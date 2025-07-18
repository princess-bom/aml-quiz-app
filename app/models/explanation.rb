class Explanation < ApplicationRecord
  belongs_to :question
  
  validates :correct_reason, presence: true
  
  # Get wrong reason for specific option
  def wrong_reason_for_option(option)
    case option.to_s
    when '1', 'A' then wrong_reason_1
    when '2', 'B' then wrong_reason_2
    when '3', 'C' then wrong_reason_3
    when '4', 'D' then wrong_reason_4
    when '5', 'E' then wrong_reason_4 # Fallback to last wrong reason
    end
  end
end
