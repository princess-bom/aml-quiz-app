class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index
    @user_sessions = QuizSession.find_by_user(current_user['uid'])
    @completed_sessions = @user_sessions.select(&:completed?)
    @wrong_answers = WrongAnswer.find_by_user(current_user['uid'])
    
    @overall_stats = calculate_overall_stats
    @subject_performance = calculate_subject_performance
    @difficulty_analysis = calculate_difficulty_analysis
    @learning_trends = calculate_learning_trends
    @weak_areas = calculate_weak_areas
    @improvement_metrics = calculate_improvement_metrics
  end

  def subject
    @subject = params[:subject]
    unless Quiz::SUBJECTS.include?(@subject)
      redirect_to analytics_path, alert: '유효하지 않은 과목입니다.'
      return
    end

    @subject_sessions = get_subject_sessions(@subject)
    @subject_wrong_answers = get_subject_wrong_answers(@subject)
    
    @subject_stats = calculate_subject_detailed_stats(@subject)
    @type_performance = calculate_type_performance(@subject)
    @difficulty_breakdown = calculate_difficulty_breakdown(@subject)
    @learning_timeline = calculate_subject_learning_timeline(@subject)
    @improvement_trends = calculate_subject_improvement_trends(@subject)
    @recommendations = generate_subject_recommendations(@subject)
  end

  private

  def calculate_overall_stats
    completed_sessions = @completed_sessions
    
    {
      total_sessions: completed_sessions.count,
      total_questions: completed_sessions.sum(&:total_questions),
      total_correct: completed_sessions.sum(&:correct_answers),
      total_score: completed_sessions.sum(&:score),
      average_score: completed_sessions.empty? ? 0 : (completed_sessions.sum(&:score).to_f / completed_sessions.count).round(1),
      overall_accuracy: calculate_overall_accuracy,
      study_time: calculate_total_study_time,
      sessions_this_week: sessions_in_period(1.week.ago),
      sessions_this_month: sessions_in_period(1.month.ago),
      improvement_rate: calculate_overall_improvement_rate
    }
  end

  def calculate_overall_accuracy
    total_questions = @completed_sessions.sum(&:total_questions)
    return 0 if total_questions == 0
    
    total_correct = @completed_sessions.sum(&:correct_answers)
    (total_correct.to_f / total_questions * 100).round(1)
  end

  def calculate_total_study_time
    total_seconds = @completed_sessions.sum do |session|
      session.session_duration || 0
    end
    
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    
    "#{hours.to_i}시간 #{minutes.to_i}분"
  end

  def sessions_in_period(start_date)
    @completed_sessions.count { |session| session.completed_at >= start_date }
  end

  def calculate_overall_improvement_rate
    return 0 if @wrong_answers.empty?
    
    retried_answers = @wrong_answers.select { |wa| wa.retry_count > 0 }
    return 0 if retried_answers.empty?
    
    successful_retries = retried_answers.count(&:last_retry_correct)
    (successful_retries.to_f / retried_answers.count * 100).round(1)
  end

  def calculate_subject_performance
    performance = {}
    
    Quiz::SUBJECTS.each do |subject|
      subject_sessions = get_subject_sessions(subject)
      subject_wrong_answers = get_subject_wrong_answers(subject)
      
      performance[subject] = {
        sessions_count: subject_sessions.count,
        total_questions: subject_sessions.sum(&:total_questions),
        total_correct: subject_sessions.sum(&:correct_answers),
        accuracy: calculate_subject_accuracy(subject_sessions),
        average_score: calculate_subject_average_score(subject_sessions),
        wrong_answers_count: subject_wrong_answers.count,
        improvement_rate: calculate_subject_improvement_rate(subject_wrong_answers),
        last_studied: subject_sessions.empty? ? nil : subject_sessions.max_by(&:completed_at)&.completed_at
      }
    end
    
    performance
  end

  def calculate_subject_accuracy(sessions)
    total_questions = sessions.sum(&:total_questions)
    return 0 if total_questions == 0
    
    total_correct = sessions.sum(&:correct_answers)
    (total_correct.to_f / total_questions * 100).round(1)
  end

  def calculate_subject_average_score(sessions)
    return 0 if sessions.empty?
    (sessions.sum(&:score).to_f / sessions.count).round(1)
  end

  def calculate_subject_improvement_rate(wrong_answers)
    retried_answers = wrong_answers.select { |wa| wa.retry_count > 0 }
    return 0 if retried_answers.empty?
    
    successful_retries = retried_answers.count(&:last_retry_correct)
    (successful_retries.to_f / retried_answers.count * 100).round(1)
  end

  def calculate_difficulty_analysis
    analysis = {}
    
    Quiz::DIFFICULTY_LEVELS.each do |difficulty|
      difficulty_sessions = get_difficulty_sessions(difficulty)
      difficulty_wrong_answers = get_difficulty_wrong_answers(difficulty)
      
      analysis[difficulty] = {
        sessions_count: difficulty_sessions.count,
        accuracy: calculate_difficulty_accuracy(difficulty_sessions),
        average_score: calculate_difficulty_average_score(difficulty_sessions),
        wrong_answers_count: difficulty_wrong_answers.count,
        subjects_breakdown: calculate_difficulty_subjects_breakdown(difficulty_wrong_answers)
      }
    end
    
    analysis
  end

  def calculate_difficulty_accuracy(sessions)
    total_questions = sessions.sum(&:total_questions)
    return 0 if total_questions == 0
    
    total_correct = sessions.sum(&:correct_answers)
    (total_correct.to_f / total_questions * 100).round(1)
  end

  def calculate_difficulty_average_score(sessions)
    return 0 if sessions.empty?
    (sessions.sum(&:score).to_f / sessions.count).round(1)
  end

  def calculate_difficulty_subjects_breakdown(wrong_answers)
    breakdown = {}
    Quiz::SUBJECTS.each do |subject|
      breakdown[subject] = wrong_answers.count { |wa| wa.subject == subject }
    end
    breakdown
  end

  def calculate_learning_trends
    # Group sessions by month
    monthly_data = @completed_sessions.group_by { |session| 
      session.completed_at.strftime('%Y-%m') 
    }
    
    trends = monthly_data.map do |month, sessions|
      {
        month: month,
        sessions_count: sessions.count,
        total_questions: sessions.sum(&:total_questions),
        total_correct: sessions.sum(&:correct_answers),
        accuracy: sessions.sum(&:total_questions) > 0 ? 
          (sessions.sum(&:correct_answers).to_f / sessions.sum(&:total_questions) * 100).round(1) : 0,
        average_score: sessions.empty? ? 0 : (sessions.sum(&:score).to_f / sessions.count).round(1),
        study_time: sessions.sum { |s| s.session_duration || 0 }
      }
    end
    
    trends.sort_by { |trend| trend[:month] }
  end

  def calculate_weak_areas
    weak_areas = []
    
    Quiz::SUBJECTS.each do |subject|
      Quiz::QUESTION_TYPES.each do |type|
        wrong_count = @wrong_answers.count { |wa| 
          wa.subject == subject && wa.question_type == type 
        }
        
        if wrong_count >= 2
          sessions_count = get_subject_type_sessions(subject, type).count
          accuracy = calculate_subject_type_accuracy(subject, type)
          
          weak_areas << {
            subject: subject,
            question_type: type,
            wrong_count: wrong_count,
            sessions_count: sessions_count,
            accuracy: accuracy,
            severity: calculate_weakness_severity(wrong_count, accuracy),
            recent_wrong_answers: @wrong_answers.select { |wa| 
              wa.subject == subject && wa.question_type == type 
            }.sort_by(&:created_at).reverse.first(3)
          }
        end
      end
    end
    
    weak_areas.sort_by { |area| -area[:severity] }
  end

  def calculate_weakness_severity(wrong_count, accuracy)
    # Severity score based on wrong count and accuracy
    base_score = wrong_count * 10
    accuracy_penalty = (100 - accuracy) * 0.5
    (base_score + accuracy_penalty).round(1)
  end

  def calculate_subject_type_accuracy(subject, question_type)
    relevant_sessions = @completed_sessions.select { |session|
      session.quiz_ids.any? { |quiz_id|
        quiz = Quiz.find(quiz_id)
        quiz&.subject == subject && quiz&.question_type == question_type
      }
    }
    
    return 0 if relevant_sessions.empty?
    
    total_questions = 0
    total_correct = 0
    
    relevant_sessions.each do |session|
      session.answers.each do |answer|
        quiz = Quiz.find(answer['quiz_id'])
        if quiz&.subject == subject && quiz&.question_type == question_type
          total_questions += 1
          total_correct += 1 if answer['is_correct']
        end
      end
    end
    
    return 0 if total_questions == 0
    (total_correct.to_f / total_questions * 100).round(1)
  end

  def calculate_improvement_metrics
    return {} if @wrong_answers.empty?
    
    {
      total_wrong_answers: @wrong_answers.count,
      retried_count: @wrong_answers.count { |wa| wa.retry_count > 0 },
      successful_retries: @wrong_answers.count(&:last_retry_correct),
      bookmarked_count: @wrong_answers.count(&:bookmarked),
      with_notes_count: @wrong_answers.count { |wa| wa.user_note.present? },
      average_retry_count: @wrong_answers.map(&:retry_count).sum.to_f / @wrong_answers.count,
      oldest_unresolved: @wrong_answers.reject(&:last_retry_correct).min_by(&:created_at)&.created_at,
      recent_improvements: @wrong_answers.select(&:last_retry_correct).count { |wa| 
        wa.updated_at >= 1.week.ago 
      }
    }
  end

  def get_subject_sessions(subject)
    @completed_sessions.select { |session|
      session.quiz_ids.any? { |quiz_id|
        quiz = Quiz.find(quiz_id)
        quiz&.subject == subject
      }
    }
  end

  def get_subject_wrong_answers(subject)
    @wrong_answers.select { |wa| wa.subject == subject }
  end

  def get_difficulty_sessions(difficulty)
    @completed_sessions.select { |session|
      session.quiz_ids.any? { |quiz_id|
        quiz = Quiz.find(quiz_id)
        quiz&.difficulty == difficulty
      }
    }
  end

  def get_difficulty_wrong_answers(difficulty)
    @wrong_answers.select { |wa| wa.difficulty == difficulty }
  end

  def get_subject_type_sessions(subject, question_type)
    @completed_sessions.select { |session|
      session.quiz_ids.any? { |quiz_id|
        quiz = Quiz.find(quiz_id)
        quiz&.subject == subject && quiz&.question_type == question_type
      }
    }
  end

  # Subject-specific analysis methods
  def calculate_subject_detailed_stats(subject)
    sessions = get_subject_sessions(subject)
    wrong_answers = get_subject_wrong_answers(subject)
    
    {
      total_sessions: sessions.count,
      total_questions: sessions.sum(&:total_questions),
      total_correct: sessions.sum(&:correct_answers),
      accuracy: calculate_subject_accuracy(sessions),
      average_score: calculate_subject_average_score(sessions),
      wrong_answers_count: wrong_answers.count,
      improvement_rate: calculate_subject_improvement_rate(wrong_answers),
      first_attempt: sessions.min_by(&:completed_at)&.completed_at,
      last_attempt: sessions.max_by(&:completed_at)&.completed_at,
      study_time: sessions.sum { |s| s.session_duration || 0 }
    }
  end

  def calculate_type_performance(subject)
    performance = {}
    
    Quiz::QUESTION_TYPES.each do |type|
      type_sessions = get_subject_type_sessions(subject, type)
      type_wrong_answers = @wrong_answers.select { |wa| 
        wa.subject == subject && wa.question_type == type 
      }
      
      performance[type] = {
        sessions_count: type_sessions.count,
        accuracy: calculate_subject_type_accuracy(subject, type),
        wrong_answers_count: type_wrong_answers.count,
        improvement_rate: calculate_subject_improvement_rate(type_wrong_answers)
      }
    end
    
    performance
  end

  def calculate_difficulty_breakdown(subject)
    breakdown = {}
    
    Quiz::DIFFICULTY_LEVELS.each do |difficulty|
      difficulty_wrong_answers = @wrong_answers.select { |wa| 
        wa.subject == subject && wa.difficulty == difficulty 
      }
      
      breakdown[difficulty] = {
        wrong_answers_count: difficulty_wrong_answers.count,
        improvement_rate: calculate_subject_improvement_rate(difficulty_wrong_answers)
      }
    end
    
    breakdown
  end

  def calculate_subject_learning_timeline(subject)
    sessions = get_subject_sessions(subject)
    wrong_answers = get_subject_wrong_answers(subject)
    
    timeline = []
    
    sessions.each do |session|
      timeline << {
        date: session.completed_at,
        type: 'quiz_completed',
        data: {
          score: session.score,
          accuracy: (session.correct_answers.to_f / session.total_questions * 100).round(1),
          questions: session.total_questions
        }
      }
    end
    
    wrong_answers.each do |wa|
      timeline << {
        date: wa.created_at,
        type: 'wrong_answer',
        data: {
          question_type: wa.question_type,
          difficulty: wa.difficulty,
          retry_count: wa.retry_count
        }
      }
    end
    
    timeline.sort_by { |item| item[:date] }
  end

  def calculate_subject_improvement_trends(subject)
    wrong_answers = get_subject_wrong_answers(subject)
    
    # Group by month
    monthly_data = wrong_answers.group_by { |wa| wa.created_at.strftime('%Y-%m') }
    
    trends = monthly_data.map do |month, was|
      retry_count = was.sum(&:retry_count)
      successful_retries = was.count(&:last_retry_correct)
      
      {
        month: month,
        wrong_answers: was.count,
        retry_count: retry_count,
        successful_retries: successful_retries,
        improvement_rate: retry_count > 0 ? (successful_retries.to_f / retry_count * 100).round(1) : 0
      }
    end
    
    trends.sort_by { |trend| trend[:month] }
  end

  def generate_subject_recommendations(subject)
    wrong_answers = get_subject_wrong_answers(subject)
    sessions = get_subject_sessions(subject)
    
    recommendations = []
    
    # Check for weak question types
    Quiz::QUESTION_TYPES.each do |type|
      type_wrong_count = wrong_answers.count { |wa| wa.question_type == type }
      if type_wrong_count >= 3
        recommendations << {
          type: 'focus_question_type',
          priority: 'high',
          message: "#{type}유형 문제에 집중 학습이 필요합니다 (#{type_wrong_count}개 오답)",
          action: {
            text: "#{type}유형 문제 풀기",
            url: start_quiz_path(subject: subject, question_type: type)
          }
        }
      end
    end
    
    # Check for difficult levels
    Quiz::DIFFICULTY_LEVELS.each do |difficulty|
      difficulty_wrong_count = wrong_answers.count { |wa| wa.difficulty == difficulty }
      if difficulty_wrong_count >= 3
        recommendations << {
          type: 'focus_difficulty',
          priority: 'medium',
          message: "#{difficulty} 난이도 문제 학습을 권장합니다 (#{difficulty_wrong_count}개 오답)",
          action: {
            text: "#{difficulty} 난이도 문제 풀기",
            url: start_quiz_path(subject: subject, difficulty: difficulty)
          }
        }
      end
    end
    
    # Check for old unresolved wrong answers
    old_wrong_answers = wrong_answers.select { |wa| 
      wa.created_at <= 1.week.ago && !wa.last_retry_correct 
    }
    
    if old_wrong_answers.count >= 5
      recommendations << {
        type: 'review_old_wrong_answers',
        priority: 'medium',
        message: "오래된 오답 #{old_wrong_answers.count}개를 다시 복습해보세요",
        action: {
          text: "오답 노트 보기",
          url: wrong_answers_path(subject: subject)
        }
      }
    end
    
    recommendations
  end
end