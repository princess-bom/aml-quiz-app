class UserAnswer < ApplicationRecord
  belongs_to :user
  belongs_to :question
  belongs_to :quiz_session
  
  validates :selected_answer, presence: true
  validates :is_correct, inclusion: { in: [true, false] }
  
  scope :correct, -> { where(is_correct: true) }
  scope :incorrect, -> { where(is_correct: false) }
  
  # Callbacks
  after_create :create_wrong_answer_if_incorrect
  
  private
  
  def create_wrong_answer_if_incorrect
    return if is_correct?
    
    WrongAnswer.create!(
      user: user,
      question: question,
      quiz_session: quiz_session,
      selected_answer: selected_answer,
      reviewed: false,
      bookmarked: false
    )
  end
end
