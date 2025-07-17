class HomeController < ApplicationController
  def index
    @active_session = QuizSession.find_by_user(current_user['uid'])
    @user_stats = calculate_user_stats
    @subject_progress = calculate_subject_progress
    @recent_activity = get_recent_activity
    @weak_areas = get_weak_areas_summary
  end

  private

  def calculate_user_stats
    user_sessions = QuizSession.find_by_user(current_user['uid'])
    completed_sessions = user_sessions.select(&:completed?)
    
    return { total_sessions: 0, average_score: 0, best_score: 0 } if completed_sessions.empty?
    
    {
      total_sessions: completed_sessions.count,
      average_score: (completed_sessions.sum(&:score).to_f / completed_sessions.count).round(1),
      best_score: completed_sessions.max_by(&:score)&.score || 0
    }
  end

  def calculate_subject_progress
    progress = {}
    
    Quiz::SUBJECTS.each do |subject|
      # Calculate completion rate for each subject
      total_combinations = Quiz::QUESTION_TYPES.count * Quiz::DIFFICULTY_LEVELS.count
      completed_combinations = 0
      
      Quiz::QUESTION_TYPES.each do |type|
        Quiz::DIFFICULTY_LEVELS.each do |difficulty|
          completed_combinations += 1 if has_completed_quiz?(subject, type, difficulty)
        end
      end
      
      progress[subject] = {
        completion_rate: total_combinations > 0 ? (completed_combinations.to_f / total_combinations * 100).round(1) : 0,
        last_studied: get_last_studied_date(subject)
      }
    end
    
    progress
  end

  def has_completed_quiz?(subject, question_type, difficulty)
    user_sessions = QuizSession.find_by_user(current_user['uid'])
    completed_sessions = user_sessions.select(&:completed?)
    
    completed_sessions.any? { |session|
      session.quiz_ids.any? { |quiz_id|
        quiz = Quiz.find(quiz_id)
        quiz&.subject == subject && 
        quiz&.question_type == question_type && 
        quiz&.difficulty == difficulty
      }
    }
  end

  def get_last_studied_date(subject)
    user_sessions = QuizSession.find_by_user(current_user['uid'])
    completed_sessions = user_sessions.select(&:completed?)
    
    subject_sessions = completed_sessions.select { |session|
      session.quiz_ids.any? { |quiz_id|
        quiz = Quiz.find(quiz_id)
        quiz&.subject == subject
      }
    }
    
    subject_sessions.max_by(&:completed_at)&.completed_at
  end

  def get_recent_activity
    user_sessions = QuizSession.find_by_user(current_user['uid'])
    completed_sessions = user_sessions.select(&:completed?)
    
    completed_sessions.sort_by(&:completed_at)
                     .reverse
                     .first(5)
                     .map do |session|
      {
        date: session.completed_at,
        score: session.score,
        accuracy: (session.correct_answers.to_f / session.total_questions * 100).round(1),
        subject: get_session_primary_subject(session)
      }
    end
  end

  def get_session_primary_subject(session)
    # Get the most common subject in the session
    subjects = session.quiz_ids.map { |quiz_id|
      Quiz.find(quiz_id)&.subject
    }.compact
    
    return "혼합" if subjects.empty?
    
    subjects.group_by(&:itself).max_by { |_, quizzes| quizzes.count }&.first || "혼합"
  end

  def get_weak_areas_summary
    wrong_answers = WrongAnswer.find_by_user(current_user['uid'])
    return [] if wrong_answers.empty?
    
    # Group by subject and count
    weak_areas = []
    
    Quiz::SUBJECTS.each do |subject|
      subject_wrong_count = wrong_answers.count { |wa| wa.subject == subject }
      
      if subject_wrong_count >= 3
        weak_areas << {
          subject: subject,
          wrong_count: subject_wrong_count,
          most_difficult_type: find_most_difficult_type(subject, wrong_answers)
        }
      end
    end
    
    weak_areas.sort_by { |area| -area[:wrong_count] }.first(3)
  end

  def find_most_difficult_type(subject, wrong_answers)
    subject_wrong_answers = wrong_answers.select { |wa| wa.subject == subject }
    
    type_counts = Quiz::QUESTION_TYPES.map { |type|
      [type, subject_wrong_answers.count { |wa| wa.question_type == type }]
    }.to_h
    
    type_counts.max_by { |_, count| count }&.first
  end
end