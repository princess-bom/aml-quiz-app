class QuizResultComponent < ViewComponent::Base
  def initialize(quiz:, session:, user_answer:, is_correct:)
    @quiz = quiz
    @session = session
    @user_answer = user_answer
    @is_correct = is_correct
  end

  private

  attr_reader :quiz, :session, :user_answer, :is_correct

  def result_color
    is_correct ? 'text-green-600' : 'text-red-600'
  end

  def result_bg_color
    is_correct ? 'bg-green-50 border-green-200' : 'bg-red-50 border-red-200'
  end

  def result_icon
    is_correct ? 'check-circle' : 'x-circle'
  end

  def result_text
    is_correct ? '정답입니다!' : '오답입니다.'
  end

  def user_choice_index
    quiz.choices.index(user_answer)
  end

  def user_choice_label
    quiz.choice_label(user_choice_index) if user_choice_index
  end

  def choice_style(choice, index)
    if choice == quiz.correct_answer
      'bg-green-100 border-green-300 text-green-800'
    elsif choice == user_answer && !is_correct
      'bg-red-100 border-red-300 text-red-800'
    else
      'bg-gray-50 border-gray-200 text-gray-700'
    end
  end

  def choice_icon(choice)
    if choice == quiz.correct_answer
      'check-circle'
    elsif choice == user_answer && !is_correct
      'x-circle'
    else
      nil
    end
  end

  def choice_icon_color(choice)
    if choice == quiz.correct_answer
      'text-green-600'
    elsif choice == user_answer && !is_correct
      'text-red-600'
    else
      'text-gray-400'
    end
  end
end