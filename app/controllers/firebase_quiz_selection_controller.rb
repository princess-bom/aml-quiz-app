class FirebaseQuizSelectionController < ApplicationController
  # Skip authentication for testing Firebase integration
  skip_before_action :authenticate_user!
  # Skip CSRF protection for testing
  skip_before_action :verify_authenticity_token
  before_action :init_firebase_service

  # 6과목 정의
  SUBJECTS = {
    1 => "자금세탁방지 글로벌 기준",
    2 => "국내 자금세탁방지 제도", 
    3 => "고객확인의무",
    4 => "고액현금거래·의심거래보고",
    5 => "위험평가",
    6 => "자금세탁방지 실무"
  }.freeze

  # 난이도 정의
  DIFFICULTY_LEVELS = %w[high medium_high highest].freeze

  def index
    @subjects = SUBJECTS
    @subject_stats = calculate_subject_stats
    @recent_sessions = recent_user_sessions
    @weak_areas = calculate_weak_areas
    @total_questions_available = get_total_questions_count
  end

  def show_subject
    @subject_id = params[:subject_id].to_i
    @subject_name = SUBJECTS[@subject_id]
    
    unless @subject_name
      redirect_to quiz_selection_path, alert: '유효하지 않은 과목입니다.'
      return
    end
    
    @difficulty_levels = DIFFICULTY_LEVELS
    @subject_questions = get_subject_questions_stats(@subject_id)
    @subject_stats = calculate_subject_detailed_stats(@subject_id)
  end

  def start_quiz
    @subject_id = params[:subject_id].to_i
    @difficulty = params[:difficulty]
    @user_id = current_user_id

    unless valid_quiz_params?
      redirect_to quiz_selection_path, alert: '유효하지 않은 퀴즈 선택입니다.'
      return
    end

    # Check if there's already an active session (temporarily disabled for testing)
    # existing_sessions = @firebase_service.get_user_quiz_sessions(@user_id)
    # active_session = existing_sessions.find { |session| session['status'] == 'active' }
    # 
    # if active_session
    #   redirect_to quiz_path(active_session['session_id']), 
    #               notice: '진행 중인 퀴즈가 있습니다. 기존 퀴즈를 완료하거나 취소해주세요.'
    #   return
    # end

    # Get questions for this subject and difficulty
    questions = @firebase_service.get_questions_by_subject_and_difficulty(@subject_id, @difficulty)
    
    if questions.empty?
      redirect_to quiz_selection_path, alert: '해당 조건의 문제가 없습니다.'
      return
    end

    # Take 20 random questions (or all if less than 20)
    selected_questions = questions.sample(20)
    
    # Create new quiz session
    session_data = {
      user_id: @user_id,
      subject_id: @subject_id,
      subject_name: SUBJECTS[@subject_id],
      difficulty: @difficulty,
      total_questions: selected_questions.count,
      current_question: 1,
      score: 0,
      correct_answers: 0,
      status: 'active',
      question_ids: selected_questions.map { |q| q['id'] },
      started_at: Time.current.to_i
    }

    begin
      result = @firebase_service.create_quiz_session(@user_id, session_data)
      session_id = result['session_id']
      
      if session_id
        redirect_to quiz_path(session_id)
      else
        raise "Session ID not found in result: #{result}"
      end
    rescue => e
      Rails.logger.error "Failed to create quiz session: #{e.message}"
      redirect_to quiz_selection_path, alert: '퀴즈를 시작할 수 없습니다. 다시 시도해주세요.'
    end
  end

  def recommended
    @recommended_quizzes = calculate_recommended_quizzes
    @weak_areas = calculate_weak_areas
  end

  private

  def init_firebase_service
    @firebase_service = FirebaseService.new
  end

  def current_user_id
    # For now, use a test user ID. In production, this would come from authentication
    params[:user_id] || session[:user_id] || 'test_user_1'
  end

  def valid_quiz_params?
    SUBJECTS.key?(@subject_id) && DIFFICULTY_LEVELS.include?(@difficulty)
  end

  def get_total_questions_count
    begin
      questions = @firebase_service.get_all_questions
      questions.count
    rescue => e
      Rails.logger.error "Failed to get questions count: #{e.message}"
      0
    end
  end

  def get_subject_questions_stats(subject_id)
    stats = {}
    
    DIFFICULTY_LEVELS.each do |difficulty|
      begin
        questions = @firebase_service.get_questions_by_subject_and_difficulty(subject_id, difficulty)
        stats[difficulty] = {
          available: questions.count,
          sample_question: questions.first
        }
      rescue => e
        Rails.logger.error "Failed to get questions for subject #{subject_id}, difficulty #{difficulty}: #{e.message}"
        stats[difficulty] = { available: 0, sample_question: nil }
      end
    end
    
    stats
  end

  def calculate_subject_stats
    stats = {}
    user_id = current_user_id
    
    begin
      user_sessions = @firebase_service.get_user_quiz_sessions(user_id)
      completed_sessions = user_sessions.select { |session| session['status'] == 'completed' }
      
      SUBJECTS.each do |subject_id, subject_name|
        subject_sessions = completed_sessions.select { |session| 
          session['subject_id'] == subject_id 
        }
        
        if subject_sessions.any?
          avg_score = subject_sessions.sum { |s| s['score'] || 0 } / subject_sessions.count.to_f
          last_played = subject_sessions.map { |s| s['completed_at'] }.compact.max
        else
          avg_score = 0
          last_played = nil
        end
        
        stats[subject_id] = {
          name: subject_name,
          total_sessions: subject_sessions.count,
          average_score: avg_score.round(1),
          last_played: last_played
        }
      end
    rescue => e
      Rails.logger.error "Failed to calculate subject stats: #{e.message}"
      # Return empty stats if Firebase fails
      SUBJECTS.each do |subject_id, subject_name|
        stats[subject_id] = {
          name: subject_name,
          total_sessions: 0,
          average_score: 0,
          last_played: nil
        }
      end
    end
    
    stats
  end

  def calculate_subject_detailed_stats(subject_id)
    stats = {}
    user_id = current_user_id
    
    DIFFICULTY_LEVELS.each do |difficulty|
      stats[difficulty] = {
        attempts: 0,
        correct: 0,
        accuracy: 0,
        average_score: 0
      }
    end
    
    begin
      user_sessions = @firebase_service.get_user_quiz_sessions(user_id)
      completed_sessions = user_sessions.select { |session| 
        session['status'] == 'completed' && session['subject_id'] == subject_id 
      }
      
      completed_sessions.each do |session|
        difficulty = session['difficulty']
        next unless DIFFICULTY_LEVELS.include?(difficulty)
        
        stats[difficulty][:attempts] += 1
        stats[difficulty][:correct] += session['correct_answers'] || 0
        stats[difficulty][:average_score] += session['score'] || 0
      end
      
      # Calculate percentages
      stats.each do |difficulty, data|
        if data[:attempts] > 0
          data[:accuracy] = (data[:correct].to_f / (data[:attempts] * 20) * 100).round(1) # 20 questions per quiz
          data[:average_score] = (data[:average_score].to_f / data[:attempts]).round(1)
        end
      end
    rescue => e
      Rails.logger.error "Failed to calculate detailed subject stats: #{e.message}"
    end
    
    stats
  end

  def calculate_weak_areas
    weak_areas = []
    user_id = current_user_id
    
    begin
      wrong_answers = @firebase_service.get_user_wrong_answers(user_id)
      
      return [] if wrong_answers.empty?
      
      # Group by subject and difficulty
      SUBJECTS.each do |subject_id, subject_name|
        DIFFICULTY_LEVELS.each do |difficulty|
          wrong_count = wrong_answers.count { |wa| 
            wa['subject_id'] == subject_id && wa['difficulty'] == difficulty
          }
          
          if wrong_count >= 2
            weak_areas << {
              subject_id: subject_id,
              subject_name: subject_name,
              difficulty: difficulty,
              wrong_count: wrong_count
            }
          end
        end
      end
      
      weak_areas.sort_by { |area| -area[:wrong_count] }
    rescue => e
      Rails.logger.error "Failed to calculate weak areas: #{e.message}"
      []
    end
  end

  def calculate_recommended_quizzes
    weak_areas = calculate_weak_areas
    recommendations = []
    
    weak_areas.first(5).each do |area| # Top 5 weak areas
      recommendations << {
        subject_id: area[:subject_id],
        subject_name: area[:subject_name],
        difficulty: area[:difficulty],
        reason: "#{area[:wrong_count]}개의 오답이 있습니다",
        priority: area[:wrong_count] > 5 ? 'high' : 'medium'
      }
    end
    
    recommendations
  end

  def recent_user_sessions
    user_id = current_user_id
    
    begin
      user_sessions = @firebase_service.get_user_quiz_sessions(user_id)
      completed_sessions = user_sessions.select { |session| session['status'] == 'completed' }
      
      # Sort by completed_at and take first 5
      completed_sessions.sort_by { |session| -(session['completed_at'] || 0) }.first(5)
    rescue => e
      Rails.logger.error "Failed to get recent sessions: #{e.message}"
      []
    end
  end
end