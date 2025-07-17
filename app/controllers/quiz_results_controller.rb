class QuizResultsController < ApplicationController
  before_action :set_quiz_session

  def show
    unless @quiz_session.completed?
      redirect_to quiz_path(@quiz_session.id), alert: '퀴즈를 완료하지 않았습니다.'
      return
    end

    @session_stats = calculate_session_stats
  end

  private

  def set_quiz_session
    @quiz_session = QuizSession.find(params[:id])
    unless @quiz_session
      redirect_to root_path, alert: '퀴즈 세션을 찾을 수 없습니다.'
      return
    end

    unless @quiz_session.user_id == current_user['uid']
      redirect_to root_path, alert: '권한이 없습니다.'
      return
    end
  end

  def calculate_session_stats
    {
      total_questions: @quiz_session.total_questions,
      correct_answers: @quiz_session.correct_answers,
      wrong_answers: @quiz_session.total_questions - @quiz_session.correct_answers,
      accuracy: @quiz_session.accuracy_percentage,
      score: @quiz_session.score,
      total_possible_score: @quiz_session.total_possible_score,
      score_percentage: @quiz_session.score_percentage,
      duration: @quiz_session.session_duration,
      grade: calculate_grade(@quiz_session.score_percentage)
    }
  end

  def calculate_grade(percentage)
    case percentage
    when 90..100
      { letter: 'A', color: 'text-green-600', bg: 'bg-green-100' }
    when 80..89
      { letter: 'B', color: 'text-blue-600', bg: 'bg-blue-100' }
    when 70..79
      { letter: 'C', color: 'text-yellow-600', bg: 'bg-yellow-100' }
    when 60..69
      { letter: 'D', color: 'text-orange-600', bg: 'bg-orange-100' }
    else
      { letter: 'F', color: 'text-red-600', bg: 'bg-red-100' }
    end
  end
end