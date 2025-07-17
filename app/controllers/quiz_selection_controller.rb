class QuizSelectionController < ApplicationController
  before_action :authenticate_user!

  def index
    @subjects = Quiz::SUBJECTS
    @subject_stats = calculate_subject_stats
    @recent_sessions = recent_user_sessions
    @weak_areas = calculate_weak_areas
  end

  def show_subject
    @subject = params[:subject]
    redirect_to quiz_selection_path unless Quiz::SUBJECTS.include?(@subject)
    
    @question_types = Quiz::QUESTION_TYPES
    @difficulty_levels = Quiz::DIFFICULTY_LEVELS
    @quiz_matrix = build_quiz_matrix(@subject)
    @subject_stats = calculate_subject_detailed_stats(@subject)
  end

  def start_quiz
    @subject = params[:subject]
    @question_type = params[:question_type]
    @difficulty = params[:difficulty]

    unless valid_quiz_params?
      redirect_to quiz_selection_path, alert: '유효하지 않은 퀴즈 선택입니다.'
      return
    end

    # Check if there's already an active session
    existing_session = QuizSession.find_by_user(current_user['uid'])
    if existing_session
      redirect_to quiz_path(existing_session.id), 
                  notice: '진행 중인 퀴즈가 있습니다. 기존 퀴즈를 완료하거나 취소해주세요.'
      return
    end

    # Create new quiz session
    @quiz_session = QuizSession.create_for_user(
      current_user['uid'],
      20, # 20 questions per quiz
      subject: @subject,
      question_type: @question_type,
      difficulty: @difficulty
    )

    if @quiz_session
      redirect_to quiz_path(@quiz_session.id)
    else
      redirect_to quiz_selection_path, alert: '퀴즈를 시작할 수 없습니다. 다시 시도해주세요.'
    end
  end

  def recommended
    @recommended_quizzes = calculate_recommended_quizzes
    @weak_areas = calculate_weak_areas
  end

  private

  def valid_quiz_params?
    Quiz::SUBJECTS.include?(@subject) &&
    Quiz::QUESTION_TYPES.include?(@question_type) &&
    Quiz::DIFFICULTY_LEVELS.include?(@difficulty)
  end

  def calculate_subject_stats
    user_sessions = QuizSession.find_by_user(current_user['uid'])
    completed_sessions = user_sessions.select(&:completed?)
    
    stats = {}
    Quiz::SUBJECTS.each do |subject|
      subject_sessions = completed_sessions.select { |session| 
        session.quiz_ids.any? { |quiz_id| 
          quiz = Quiz.find(quiz_id)
          quiz&.subject == subject
        }
      }
      
      stats[subject] = {
        total_sessions: subject_sessions.count,
        average_score: subject_sessions.empty? ? 0 : subject_sessions.sum(&:score) / subject_sessions.count,
        completion_rate: calculate_completion_rate(subject),
        last_played: subject_sessions.empty? ? nil : subject_sessions.max_by(&:completed_at)&.completed_at
      }
    end
    
    stats
  end

  def calculate_subject_detailed_stats(subject)
    user_sessions = QuizSession.find_by_user(current_user['uid'])
    completed_sessions = user_sessions.select(&:completed?)
    
    # Filter sessions that contain quizzes from this subject
    subject_sessions = completed_sessions.select { |session|
      session.quiz_ids.any? { |quiz_id|
        quiz = Quiz.find(quiz_id)
        quiz&.subject == subject
      }
    }
    
    type_stats = {}
    Quiz::QUESTION_TYPES.each do |type|
      Quiz::DIFFICULTY_LEVELS.each do |difficulty|
        type_stats["#{type}_#{difficulty}"] = {
          attempts: 0,
          correct: 0,
          accuracy: 0,
          average_score: 0
        }
      end
    end
    
    # Calculate detailed stats for each type/difficulty combination
    subject_sessions.each do |session|
      session.answers.each do |answer|
        quiz = Quiz.find(answer['quiz_id'])
        next unless quiz&.subject == subject
        
        key = "#{quiz.question_type}_#{quiz.difficulty}"
        type_stats[key][:attempts] += 1
        type_stats[key][:correct] += 1 if answer['is_correct']
        type_stats[key][:average_score] += answer['score']
      end
    end
    
    # Calculate percentages
    type_stats.each do |key, stats|
      if stats[:attempts] > 0
        stats[:accuracy] = (stats[:correct].to_f / stats[:attempts] * 100).round(1)
        stats[:average_score] = (stats[:average_score].to_f / stats[:attempts]).round(1)
      end
    end
    
    type_stats
  end

  def build_quiz_matrix(subject)
    matrix = {}
    Quiz::QUESTION_TYPES.each do |type|
      matrix[type] = {}
      Quiz::DIFFICULTY_LEVELS.each do |difficulty|
        quiz_count = Quiz.by_subject_type_difficulty(subject, type, difficulty).count
        matrix[type][difficulty] = {
          available: quiz_count,
          completed: calculate_completion_status(subject, type, difficulty),
          recommended: is_recommended_quiz?(subject, type, difficulty)
        }
      end
    end
    matrix
  end

  def calculate_completion_status(subject, question_type, difficulty)
    user_sessions = QuizSession.find_by_user(current_user['uid'])
    completed_sessions = user_sessions.select(&:completed?)
    
    # Check if user has completed a quiz with this exact combination
    completed_sessions.any? { |session|
      session.quiz_ids.any? { |quiz_id|
        quiz = Quiz.find(quiz_id)
        quiz&.subject == subject && 
        quiz&.question_type == question_type && 
        quiz&.difficulty == difficulty
      }
    }
  end

  def calculate_completion_rate(subject)
    total_combinations = Quiz::QUESTION_TYPES.count * Quiz::DIFFICULTY_LEVELS.count
    completed_combinations = 0
    
    Quiz::QUESTION_TYPES.each do |type|
      Quiz::DIFFICULTY_LEVELS.each do |difficulty|
        completed_combinations += 1 if calculate_completion_status(subject, type, difficulty)
      end
    end
    
    return 0 if total_combinations == 0
    (completed_combinations.to_f / total_combinations * 100).round(1)
  end

  def is_recommended_quiz?(subject, question_type, difficulty)
    # Simple recommendation logic - can be enhanced later
    wrong_answers = WrongAnswer.find_by_user(current_user['uid'])
    subject_wrong_answers = wrong_answers.select { |wa| wa.subject == subject }
    
    return false if subject_wrong_answers.empty?
    
    # Recommend if user has many wrong answers in this category
    category_wrong_count = subject_wrong_answers.count { |wa| 
      wa.question_type == question_type && wa.difficulty == difficulty 
    }
    
    category_wrong_count >= 2 # Recommend if 2 or more wrong answers
  end

  def calculate_weak_areas
    wrong_answers = WrongAnswer.find_by_user(current_user['uid'])
    return [] if wrong_answers.empty?
    
    # Group by subject and question type
    weak_areas = []
    
    Quiz::SUBJECTS.each do |subject|
      Quiz::QUESTION_TYPES.each do |type|
        wrong_count = wrong_answers.count { |wa| 
          wa.subject == subject && wa.question_type == type 
        }
        
        if wrong_count >= 2
          weak_areas << {
            subject: subject,
            question_type: type,
            wrong_count: wrong_count,
            difficulty_distribution: Quiz::DIFFICULTY_LEVELS.map { |diff|
              [diff, wrong_answers.count { |wa| 
                wa.subject == subject && wa.question_type == type && wa.difficulty == diff
              }]
            }.to_h
          }
        end
      end
    end
    
    weak_areas.sort_by { |area| -area[:wrong_count] }
  end

  def calculate_recommended_quizzes
    weak_areas = calculate_weak_areas
    recommendations = []
    
    weak_areas.first(5).each do |area| # Top 5 weak areas
      # Recommend the difficulty level where user has most wrong answers
      recommended_difficulty = area[:difficulty_distribution].max_by { |_, count| count }.first
      
      recommendations << {
        subject: area[:subject],
        question_type: area[:question_type],
        difficulty: recommended_difficulty,
        reason: "#{area[:wrong_count]}개의 오답이 있습니다",
        priority: area[:wrong_count] > 5 ? 'high' : 'medium'
      }
    end
    
    recommendations
  end

  def recent_user_sessions
    QuizSession.find_by_user(current_user['uid'])
               .select(&:completed?)
               .sort_by(&:completed_at)
               .reverse
               .first(5)
  end
end