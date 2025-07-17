class QuizQuestionComponent < ViewComponent::Base
  def initialize(quiz:, session:)
    @quiz = quiz
    @session = session
  end

  private

  attr_reader :quiz, :session

  def difficulty_color
    case quiz.difficulty
    when 'easy'
      'bg-green-100 text-green-800'
    when 'medium'
      'bg-yellow-100 text-yellow-800'
    when 'hard'
      'bg-red-100 text-red-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def score_color
    case quiz.score
    when 5
      'text-green-600'
    when 10
      'text-blue-600'
    when 15
      'text-purple-600'
    else
      'text-gray-600'
    end
  end
end