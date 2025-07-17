class QuizzesController < ApplicationController
  before_action :set_quiz_session, only: [:show, :answer]

  def new
    existing_session = QuizSession.find_by_user(current_user['uid'])
    if existing_session
      redirect_to quiz_path(existing_session.id), notice: '진행 중인 퀴즈가 있습니다.'
    else
      @quiz_session = QuizSession.create_for_user(current_user['uid'])
      redirect_to quiz_path(@quiz_session.id)
    end
  end

  def show
    if @quiz_session.completed?
      redirect_to quiz_result_path(@quiz_session.id)
      return
    end

    @current_quiz = @quiz_session.current_quiz
    unless @current_quiz
      redirect_to root_path, alert: '퀴즈를 찾을 수 없습니다.'
      return
    end

    @progress = @quiz_session.progress_percentage
  end

  def answer
    user_answer = params[:answer]
    
    unless user_answer.present?
      redirect_to quiz_path(@quiz_session.id), alert: '답안을 선택해주세요.'
      return
    end

    @is_correct = @quiz_session.submit_answer(user_answer)
    @current_quiz = Quiz.find(@quiz_session.quiz_ids[@quiz_session.current_quiz_index - 1])
    @selected_answer = user_answer
    
    if @quiz_session.completed?
      redirect_to quiz_result_path(@quiz_session.id)
    else
      # Show answer result page, then redirect to next question
      render :answer
    end
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
end