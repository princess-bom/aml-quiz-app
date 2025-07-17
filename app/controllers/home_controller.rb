class HomeController < ApplicationController
  def index
    @active_session = QuizSession.find_by_user(current_user['uid'])
    @user_stats = calculate_user_stats
  end

  private

  def calculate_user_stats
    # This would typically come from a user stats service
    # For now, return basic stats
    {
      total_sessions: 0,
      average_score: 0,
      best_score: 0,
      total_questions_answered: 0
    }
  end
end