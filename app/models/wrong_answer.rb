class WrongAnswer < ApplicationRecord
  belongs_to :user
  belongs_to :question
  belongs_to :quiz_session
  
  validates :selected_answer, presence: true
  
  scope :reviewed, -> { where(reviewed: true) }
  scope :not_reviewed, -> { where(reviewed: false) }
  scope :bookmarked, -> { where(bookmarked: true) }
  
  # Mark as reviewed
  def mark_as_reviewed!
    update!(reviewed: true)
  end
  
  # Toggle bookmark status
  def toggle_bookmark!
    update!(bookmarked: !bookmarked)
  end
  
  # Get subject name from question
  def subject_name
    question.subject_name
  end
  
  # Get difficulty from question
  def difficulty
    question.difficulty
  end
end
