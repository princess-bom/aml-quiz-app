class User < ApplicationRecord
  has_many :quiz_sessions, dependent: :destroy
  has_many :user_answers, dependent: :destroy
  has_many :wrong_answers, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :firebase_uid, presence: true, uniqueness: true
  
  # Calculate user statistics
  def calculate_average_score
    completed_sessions = quiz_sessions.where(status: 'completed')
    return 0.0 if completed_sessions.empty?
    
    completed_sessions.average(:score) || 0.0
  end
  
  def update_statistics!
    self.total_sessions = quiz_sessions.where(status: 'completed').count
    self.average_score = calculate_average_score
    save!
  end
  
  # Get wrong answers count for different statuses
  def wrong_answers_count(reviewed: nil)
    scope = wrong_answers
    scope = scope.where(reviewed: reviewed) unless reviewed.nil?
    scope.count
  end
end
