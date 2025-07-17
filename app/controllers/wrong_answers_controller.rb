class WrongAnswersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_wrong_answer, only: [:show, :update, :destroy, :toggle_bookmark, :update_note]

  def index
    @filters = filter_params
    @wrong_answers = WrongAnswer.find_by_user_and_filters(current_user['uid'], @filters)
    @statistics = WrongAnswer.user_statistics(current_user['uid'])
    @subjects = Quiz::SUBJECTS
    @question_types = Quiz::QUESTION_TYPES
    @difficulty_levels = Quiz::DIFFICULTY_LEVELS
    
    # Pagination
    @page = params[:page]&.to_i || 1
    @per_page = 10
    @total_pages = (@wrong_answers.count / @per_page.to_f).ceil
    @wrong_answers = @wrong_answers[(@page - 1) * @per_page, @per_page] || []
  end

  def show
    @quiz = @wrong_answer.quiz
    @related_wrong_answers = WrongAnswer.find_by_user_and_subject(current_user['uid'], @wrong_answer.subject)
                                       .reject { |wa| wa.id == @wrong_answer.id }
                                       .first(5)
  end

  def update_note
    if @wrong_answer.update_note(params[:note])
      render json: { success: true, message: '메모가 저장되었습니다.' }
    else
      render json: { success: false, message: '메모 저장에 실패했습니다.' }
    end
  end

  def toggle_bookmark
    if @wrong_answer.toggle_bookmark
      render json: { 
        success: true, 
        bookmarked: @wrong_answer.bookmarked,
        message: @wrong_answer.bookmarked ? '즐겨찾기에 추가되었습니다.' : '즐겨찾기에서 제거되었습니다.'
      }
    else
      render json: { success: false, message: '즐겨찾기 변경에 실패했습니다.' }
    end
  end

  def destroy
    if @wrong_answer.destroy
      redirect_to wrong_answers_path, notice: '오답이 삭제되었습니다.'
    else
      redirect_to wrong_answers_path, alert: '오답 삭제에 실패했습니다.'
    end
  end

  def retry_quiz
    @wrong_answer = WrongAnswer.find(params[:id])
    unless @wrong_answer&.user_id == current_user['uid']
      redirect_to wrong_answers_path, alert: '권한이 없습니다.'
      return
    end

    # Create a single-question quiz session for retry
    quiz = @wrong_answer.quiz
    unless quiz
      redirect_to wrong_answers_path, alert: '문제를 찾을 수 없습니다.'
      return
    end

    @quiz_session = QuizSession.create_for_user(
      current_user['uid'],
      1, # Single question
      subject: quiz.subject,
      question_type: quiz.question_type,
      difficulty: quiz.difficulty
    )

    if @quiz_session
      redirect_to quiz_path(@quiz_session.id)
    else
      redirect_to wrong_answers_path, alert: '퀴즈를 시작할 수 없습니다.'
    end
  end

  def bulk_retry
    wrong_answer_ids = params[:wrong_answer_ids] || []
    
    if wrong_answer_ids.empty?
      redirect_to wrong_answers_path, alert: '선택된 오답이 없습니다.'
      return
    end

    # Verify ownership and collect quizzes
    wrong_answers = wrong_answer_ids.map { |id| WrongAnswer.find(id) }
                                   .compact
                                   .select { |wa| wa.user_id == current_user['uid'] }

    if wrong_answers.empty?
      redirect_to wrong_answers_path, alert: '유효한 오답이 선택되지 않았습니다.'
      return
    end

    # Create quiz session with selected wrong answer quizzes
    quiz_ids = wrong_answers.map(&:quiz_id).uniq
    
    session = QuizSession.new(
      id: SecureRandom.uuid,
      user_id: current_user['uid'],
      quiz_ids: quiz_ids,
      total_questions: quiz_ids.count,
      started_at: Time.current,
      status: 'active'
    )

    if session.save
      redirect_to quiz_path(session.id)
    else
      redirect_to wrong_answers_path, alert: '오답 재시도 퀴즈를 시작할 수 없습니다.'
    end
  end

  def export
    @wrong_answers = WrongAnswer.find_by_user(current_user['uid'])
    
    respond_to do |format|
      format.csv do
        csv_data = generate_csv(@wrong_answers)
        send_data csv_data, filename: "wrong_answers_#{Date.current}.csv"
      end
      
      format.json do
        render json: @wrong_answers.map(&:to_hash)
      end
    end
  end

  def analytics
    @statistics = WrongAnswer.user_statistics(current_user['uid'])
    @wrong_answers = WrongAnswer.find_by_user(current_user['uid'])
    @subject_analysis = analyze_by_subject
    @difficulty_analysis = analyze_by_difficulty
    @improvement_trends = analyze_improvement_trends
  end

  private

  def set_wrong_answer
    @wrong_answer = WrongAnswer.find(params[:id])
    unless @wrong_answer&.user_id == current_user['uid']
      redirect_to wrong_answers_path, alert: '권한이 없습니다.'
    end
  end

  def filter_params
    params.permit(:subject, :question_type, :difficulty, :search, :bookmarked)
  end

  def generate_csv(wrong_answers)
    require 'csv'
    
    CSV.generate do |csv|
      csv << ['질문', '과목', '유형', '난이도', '내 답안', '정답', '설명', '참고자료', '메모', '즐겨찾기', '재시도 횟수', '생성일']
      
      wrong_answers.each do |wa|
        csv << [
          wa.question,
          wa.subject,
          wa.question_type,
          wa.difficulty,
          wa.user_answer,
          wa.correct_answer,
          wa.explanation,
          wa.reference,
          wa.user_note,
          wa.bookmarked ? '예' : '아니오',
          wa.retry_count,
          wa.created_at.strftime('%Y-%m-%d %H:%M')
        ]
      end
    end
  end

  def analyze_by_subject
    wrong_answers = WrongAnswer.find_by_user(current_user['uid'])
    analysis = {}
    
    Quiz::SUBJECTS.each do |subject|
      subject_wrong_answers = wrong_answers.select { |wa| wa.subject == subject }
      
      analysis[subject] = {
        total_count: subject_wrong_answers.count,
        by_type: Quiz::QUESTION_TYPES.map { |type|
          [type, subject_wrong_answers.count { |wa| wa.question_type == type }]
        }.to_h,
        by_difficulty: Quiz::DIFFICULTY_LEVELS.map { |diff|
          [diff, subject_wrong_answers.count { |wa| wa.difficulty == diff }]
        }.to_h,
        improvement_rate: calculate_subject_improvement_rate(subject_wrong_answers)
      }
    end
    
    analysis
  end

  def analyze_by_difficulty
    wrong_answers = WrongAnswer.find_by_user(current_user['uid'])
    
    Quiz::DIFFICULTY_LEVELS.map { |difficulty|
      difficulty_wrong_answers = wrong_answers.select { |wa| wa.difficulty == difficulty }
      
      [difficulty, {
        count: difficulty_wrong_answers.count,
        subjects: Quiz::SUBJECTS.map { |subject|
          [subject, difficulty_wrong_answers.count { |wa| wa.subject == subject }]
        }.to_h,
        improvement_rate: calculate_subject_improvement_rate(difficulty_wrong_answers)
      }]
    }.to_h
  end

  def analyze_improvement_trends
    wrong_answers = WrongAnswer.find_by_user(current_user['uid'])
    
    # Group by month
    monthly_data = wrong_answers.group_by { |wa| wa.created_at.strftime('%Y-%m') }
    
    trends = monthly_data.map do |month, was|
      retry_count = was.sum(&:retry_count)
      successful_retries = was.count(&:last_retry_correct)
      
      {
        month: month,
        total_wrong: was.count,
        retry_count: retry_count,
        successful_retries: successful_retries,
        improvement_rate: retry_count > 0 ? (successful_retries.to_f / retry_count * 100).round(1) : 0
      }
    end
    
    trends.sort_by { |trend| trend[:month] }
  end

  def calculate_subject_improvement_rate(wrong_answers)
    retried_answers = wrong_answers.select { |wa| wa.retry_count > 0 }
    return 0 if retried_answers.empty?
    
    correct_retries = retried_answers.count(&:last_retry_correct)
    (correct_retries.to_f / retried_answers.count * 100).round(1)
  end
end