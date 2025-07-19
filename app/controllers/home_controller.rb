class HomeController < ApplicationController
  # Skip authentication for testing Firebase integration
  skip_before_action :authenticate_user!
  # Skip CSRF protection for testing
  skip_before_action :verify_authenticity_token

  def index
    # Simplified for testing - use default values
    @user_stats = {
      total_sessions: 0,
      average_score: 0,
      best_score: 0,
      study_streak: 0
    }
    @subject_progress = []
    @recent_activity = []
    @weak_areas = []
    @active_quiz_sessions = 0
  end

  private

  def init_firebase_service
    @firebase_service = FirebaseService.new
  end

  def current_user_id
    # For now, use test user ID. In production, this would come from authentication
    session[:user_id] || 'test_user_1'
  end

  def calculate_user_stats
    begin
      user_stats = @firebase_service.get_user_stats(current_user_id) || {}
      
      {
        total_sessions: user_stats['total_sessions'] || 0,
        average_score: user_stats['average_score'] || 0,
        best_score: user_stats['best_score'] || 0,
        study_streak: user_stats['study_streak'] || 0
      }
    rescue => e
      Rails.logger.error "Failed to get user stats: #{e.message}"
      { total_sessions: 0, average_score: 0, best_score: 0, study_streak: 0 }
    end
  end

  def calculate_subject_progress
    progress = {}
    subjects = {
      1 => "자금세탁방지 글로벌 기준",
      2 => "국내 자금세탁방지 제도", 
      3 => "고객확인의무",
      4 => "고액현금거래·의심거래보고",
      5 => "위험평가",
      6 => "자금세탁방지 실무"
    }
    
    begin
      user_sessions = @firebase_service.get_user_quiz_sessions(current_user_id)
      completed_sessions = user_sessions.select { |session| session['status'] == 'completed' }
      
      subjects.each do |subject_id, subject_name|
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
        
        progress[subject_name] = {
          completion_rate: subject_sessions.count > 0 ? [avg_score, 100].min : 0,
          last_studied: last_played ? Time.at(last_played) : nil,
          sessions_count: subject_sessions.count
        }
      end
    rescue => e
      Rails.logger.error "Failed to calculate subject progress: #{e.message}"
      subjects.each { |_, name| progress[name] = { completion_rate: 0, last_studied: nil, sessions_count: 0 } }
    end
    
    progress
  end

  def get_recent_activity
    begin
      user_sessions = @firebase_service.get_user_quiz_sessions(current_user_id)
      completed_sessions = user_sessions.select { |session| session['status'] == 'completed' }
      
      completed_sessions.sort_by { |session| -(session['completed_at'] || 0) }
                       .first(5)
                       .map do |session|
        {
          date: Time.at(session['completed_at'] || 0),
          score: session['score'] || 0,
          accuracy: session['correct_answers'] && session['total_questions'] ? 
                    (session['correct_answers'].to_f / session['total_questions'] * 100).round(1) : 0,
          subject: session['subject_name'] || "알 수 없음"
        }
      end
    rescue => e
      Rails.logger.error "Failed to get recent activity: #{e.message}"
      []
    end
  end

  def get_weak_areas_summary
    begin
      wrong_answers = @firebase_service.get_user_wrong_answers(current_user_id)
      return [] if wrong_answers.empty?
      
      # Group by subject and count
      weak_areas = []
      subjects = {
        1 => "자금세탁방지 글로벌 기준",
        2 => "국내 자금세탁방지 제도", 
        3 => "고객확인의무",
        4 => "고액현금거래·의심거래보고",
        5 => "위험평가",
        6 => "자금세탁방지 실무"
      }
      
      subjects.each do |subject_id, subject_name|
        subject_wrong_count = wrong_answers.count { |wa| wa['subject_id'] == subject_id }
        
        if subject_wrong_count >= 2
          weak_areas << {
            subject: subject_name,
            wrong_count: subject_wrong_count,
            subject_id: subject_id
          }
        end
      end
      
      weak_areas.sort_by { |area| -area[:wrong_count] }.first(3)
    rescue => e
      Rails.logger.error "Failed to get weak areas: #{e.message}"
      []
    end
  end

  def get_active_sessions_count
    begin
      user_sessions = @firebase_service.get_user_quiz_sessions(current_user_id)
      user_sessions.count { |session| session['status'] == 'active' }
    rescue => e
      Rails.logger.error "Failed to get active sessions count: #{e.message}"
      0
    end
  end
end