class FirebaseQuizzesController < ApplicationController
  # Skip authentication for testing Firebase integration
  skip_before_action :authenticate_user!
  # Skip CSRF protection for testing
  skip_before_action :verify_authenticity_token
  before_action :init_firebase_service
  before_action :find_quiz_session, only: [:show, :answer, :complete]

  def show
    unless @quiz_session
      redirect_to root_path, alert: '퀴즈 세션을 찾을 수 없습니다.'
      return
    end

    if @quiz_session['status'] == 'completed'
      redirect_to result_quiz_path(@session_id)
      return
    end

    # Get current question
    current_question_index = (@quiz_session['current_question'] || 1) - 1
    question_ids = @quiz_session['question_ids'] || []
    
    if current_question_index >= question_ids.length
      # Quiz is finished, redirect to complete
      redirect_to complete_firebase_quiz_path(@session_id)
      return
    end

    current_question_id = question_ids[current_question_index]
    @current_question = @firebase_service.get_question(current_question_id)
    @current_explanation = @firebase_service.get_explanation(current_question_id)
    
    unless @current_question
      redirect_to root_path, alert: '문제를 불러올 수 없습니다.'
      return
    end

    @question_number = @quiz_session['current_question'] || 1
    @total_questions = @quiz_session['total_questions'] || 20
    @progress_percentage = ((@question_number - 1).to_f / @total_questions * 100).round
    
    # Check if user already answered this question
    user_answers = get_user_answers_for_session(@session_id)
    @user_answer = user_answers.find { |answer| answer['question_id'] == current_question_id }
    @show_explanation = @user_answer.present?
  end

  def answer
    question_id = params[:question_id].to_i
    selected_answer = params[:selected_answer]
    user_id = current_user_id

    unless @quiz_session && question_id && selected_answer
      render json: { error: '잘못된 요청입니다.' }, status: :bad_request
      return
    end

    # Get the question to check correct answer
    question = @firebase_service.get_question(question_id)
    unless question
      render json: { error: '문제를 찾을 수 없습니다.' }, status: :not_found
      return
    end

    # Check if answer is correct
    is_correct = question['correct_answer'].to_s == selected_answer.to_s
    
    # Save user answer
    answer_data = {
      user_id: user_id,
      session_id: @session_id,
      question_id: question_id,
      selected_answer: selected_answer,
      correct_answer: question['correct_answer'],
      is_correct: is_correct,
      subject_id: question['subject_id'],
      difficulty: question['difficulty'],
      answered_at: Time.current.to_i
    }

    @firebase_service.save_user_answer(user_id, @session_id, answer_data)

    # Save wrong answer if incorrect
    if !is_correct
      wrong_answer_data = {
        user_id: user_id,
        session_id: @session_id,
        question_id: question_id,
        selected_answer: selected_answer,
        correct_answer: question['correct_answer'],
        subject_id: question['subject_id'],
        subject_name: question['subject_name'],
        difficulty: question['difficulty'],
        reviewed: false,
        bookmarked: false
      }
      @firebase_service.save_wrong_answer(user_id, wrong_answer_data)
    end

    # Update quiz session progress
    current_question = @quiz_session['current_question'] || 1
    correct_answers = (@quiz_session['correct_answers'] || 0) + (is_correct ? 1 : 0)
    
    updated_session = @quiz_session.merge({
      'current_question' => current_question + 1,
      'correct_answers' => correct_answers,
      'last_answered_at' => Time.current.to_i
    })

    # Update session in Firebase
    update_quiz_session(updated_session)

    # Get explanation
    explanation = @firebase_service.get_explanation(question_id)

    render json: {
      is_correct: is_correct,
      correct_answer: question['correct_answer'],
      explanation: explanation,
      progress: {
        current_question: current_question + 1,
        total_questions: @quiz_session['total_questions'] || 20,
        correct_answers: correct_answers
      }
    }
  end

  def complete
    unless @quiz_session
      redirect_to root_path, alert: '퀴즈 세션을 찾을 수 없습니다.'
      return
    end

    if @quiz_session['status'] == 'completed'
      redirect_to result_quiz_path(@session_id)
      return
    end

    # Calculate final score
    total_questions = @quiz_session['total_questions'] || 20
    correct_answers = @quiz_session['correct_answers'] || 0
    final_score = (correct_answers.to_f / total_questions * 100).round(2)

    # Update session as completed
    completed_session = @quiz_session.merge({
      'status' => 'completed',
      'score' => final_score,
      'completed_at' => Time.current.to_i
    })

    update_quiz_session(completed_session)

    # Update user statistics
    update_user_statistics(current_user_id, final_score)

    redirect_to result_quiz_path(@session_id)
  end

  def result
    @session_id = params[:id]
    @quiz_session = get_quiz_session(@session_id)

    unless @quiz_session && @quiz_session['status'] == 'completed'
      redirect_to root_path, alert: '완료된 퀴즈 결과를 찾을 수 없습니다.'
      return
    end

    @total_questions = @quiz_session['total_questions'] || 20
    @correct_answers = @quiz_session['correct_answers'] || 0
    @final_score = @quiz_session['score'] || 0
    @subject_name = @quiz_session['subject_name']
    @difficulty = @quiz_session['difficulty']
    
    # Get detailed answers for review
    @user_answers = get_user_answers_for_session(@session_id)
    @questions_with_answers = build_questions_with_answers(@user_answers)
    
    # Calculate grade
    @grade = calculate_grade(@final_score)
    
    # Get improvement suggestions
    @suggestions = generate_improvement_suggestions
  end

  def abandon
    @session_id = params[:id]
    @quiz_session = get_quiz_session(@session_id)

    if @quiz_session && @quiz_session['status'] == 'active'
      abandoned_session = @quiz_session.merge({
        'status' => 'abandoned',
        'abandoned_at' => Time.current.to_i
      })
      update_quiz_session(abandoned_session)
    end

    redirect_to root_path, notice: '퀴즈를 포기했습니다.'
  end

  private

  def init_firebase_service
    @firebase_service = FirebaseService.new
  end

  def current_user_id
    # For now, use a test user ID. In production, this would come from authentication
    params[:user_id] || session[:user_id] || 'test_user_1'
  end

  def find_quiz_session
    @session_id = params[:id]
    @quiz_session = get_quiz_session(@session_id)
  end

  def get_quiz_session(session_id)
    begin
      user_sessions = @firebase_service.get_user_quiz_sessions(current_user_id)
      user_sessions.find { |session| session['session_id'] == session_id }
    rescue => e
      Rails.logger.error "Failed to get quiz session: #{e.message}"
      nil
    end
  end

  def update_quiz_session(session_data)
    begin
      # Firebase doesn't have a direct update method, so we recreate the session
      @firebase_service.create_quiz_session(current_user_id, session_data)
    rescue => e
      Rails.logger.error "Failed to update quiz session: #{e.message}"
    end
  end

  def get_user_answers_for_session(session_id)
    begin
      # In a real implementation, we'd have a specific method for this
      # For now, we'll simulate by getting all user answers and filtering
      user_id = current_user_id
      url = "#{@firebase_service.base_url}/users/#{user_id}/answers/#{session_id}.json"
      response = @firebase_service.send(:make_request, :get, url)
      
      return [] unless response
      
      answers = []
      response.each do |question_id, answer_data|
        answers << answer_data.merge('question_id' => question_id.to_i)
      end
      
      answers
    rescue => e
      Rails.logger.error "Failed to get user answers: #{e.message}"
      []
    end
  end

  def build_questions_with_answers(user_answers)
    questions_with_answers = []
    
    user_answers.each do |answer|
      question = @firebase_service.get_question(answer['question_id'])
      explanation = @firebase_service.get_explanation(answer['question_id'])
      
      if question
        questions_with_answers << {
          question: question,
          explanation: explanation,
          user_answer: answer
        }
      end
    end
    
    questions_with_answers
  end

  def update_user_statistics(user_id, score)
    begin
      # Get current stats
      current_stats = @firebase_service.get_user_stats(user_id) || {}
      
      # Update stats
      total_sessions = (current_stats['total_sessions'] || 0) + 1
      total_score = (current_stats['total_score'] || 0) + score
      average_score = (total_score / total_sessions).round(2)
      
      # Update study streak
      last_study_date = current_stats['last_study_date']
      today = Date.current.to_s
      study_streak = current_stats['study_streak'] || 0
      
      if last_study_date == today
        # Same day, don't change streak
      elsif last_study_date == (Date.current - 1.day).to_s
        # Consecutive day, increment streak
        study_streak += 1
      else
        # Streak broken, reset to 1
        study_streak = 1
      end
      
      updated_stats = {
        total_sessions: total_sessions,
        total_score: total_score,
        average_score: average_score,
        study_streak: study_streak,
        last_study_date: today,
        last_score: score,
        updated_at: Time.current.to_i
      }
      
      @firebase_service.update_user_stats(user_id, updated_stats)
    rescue => e
      Rails.logger.error "Failed to update user statistics: #{e.message}"
    end
  end

  def calculate_grade(score)
    case score
    when 90..100 then 'A'
    when 80..89 then 'B'
    when 70..79 then 'C'
    when 60..69 then 'D'
    else 'F'
    end
  end

  def generate_improvement_suggestions
    suggestions = []
    
    if @final_score < 60
      suggestions << "기초 개념 복습이 필요합니다. 오답노트를 활용해 보세요."
    elsif @final_score < 80
      suggestions << "좋은 성과입니다! 틀린 문제들을 다시 한번 검토해 보세요."
    else
      suggestions << "훌륭한 성과입니다! 다른 과목이나 더 높은 난이도에 도전해 보세요."
    end
    
    # Add difficulty-specific suggestions
    case @difficulty
    when 'high'
      suggestions << "기본 난이도를 완료했습니다. '중상' 난이도에 도전해 보세요."
    when 'medium_high'
      suggestions << "중상 난이도를 완료했습니다. '최상' 난이도로 실력을 시험해 보세요."
    when 'highest'
      suggestions << "최상 난이도를 완료했습니다. 다른 과목의 최상 난이도에 도전해 보세요."
    end
    
    suggestions
  end
end