class Question < ApplicationRecord
  has_one :explanation, dependent: :destroy
  has_many :user_answers, dependent: :destroy
  has_many :wrong_answers, dependent: :destroy
  
  validates :subject_id, presence: true
  validates :subject_name, presence: true
  validates :difficulty, presence: true
  validates :question_text, presence: true
  validates :correct_answer, presence: true
  
  scope :by_subject, ->(subject_id) { where(subject_id: subject_id) }
  scope :by_difficulty, ->(difficulty) { where(difficulty: difficulty) }
  scope :by_source_type, ->(source_type) { where(source_type: source_type) }
  
  # Get answer options as an array
  def answer_options
    [option_1, option_2, option_3, option_4, option_5].compact
  end
  
  # Get answer options with letters (A, B, C, D, E)
  def formatted_options
    options = []
    options << { letter: 'A', text: option_1 } if option_1.present?
    options << { letter: 'B', text: option_2 } if option_2.present?
    options << { letter: 'C', text: option_3 } if option_3.present?
    options << { letter: 'D', text: option_4 } if option_4.present?
    options << { letter: 'E', text: option_5 } if option_5.present?
    options
  end
  
  # Check if answer is correct
  def correct_answer?(answer)
    correct_answer.to_s == answer.to_s
  end
  
  # Get correct answer text
  def correct_answer_text
    case correct_answer.to_s
    when '1', 'A' then option_1
    when '2', 'B' then option_2
    when '3', 'C' then option_3
    when '4', 'D' then option_4
    when '5', 'E' then option_5
    end
  end
end
