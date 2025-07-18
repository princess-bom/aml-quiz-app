class QuizSession < ApplicationRecord
  belongs_to :user
  has_many :user_answers, dependent: :destroy
  has_many :wrong_answers, dependent: :destroy
  
  validates :user_id, presence: true
  validates :subject_id, presence: true
  validates :difficulty, presence: true
  validates :status, inclusion: { in: %w[in_progress completed] }
  
  scope :completed, -> { where(status: 'completed') }
  scope :in_progress, -> { where(status: 'in_progress') }
  
  # Quiz session management
  def complete!
    self.status = 'completed'
    self.end_time = Time.current
    self.score = calculate_score
    save!
    
    # Update user statistics
    user.update_statistics!
  end
  
  def next_question
    current_question + 1
  end
  
  def progress_percentage
    return 0 if total_questions.zero?
    ((current_question - 1).to_f / total_questions * 100).round(1)
  end
  
  def duration_in_minutes
    return 0 unless start_time && end_time
    ((end_time - start_time) / 60.0).round(1)
  end
  
  def correct_answers_count
    user_answers.where(is_correct: true).count
  end
  
  def wrong_answers_count
    user_answers.where(is_correct: false).count
  end
  
  def accuracy_percentage
    return 0 if user_answers.empty?
    (correct_answers_count.to_f / user_answers.count * 100).round(1)
  end
  
  private
  
  def calculate_score
    return 0 if user_answers.empty?
    
    correct_count = correct_answers_count
    total_count = user_answers.count
    
    (correct_count.to_f / total_count * 100).round(2)
  end
end
