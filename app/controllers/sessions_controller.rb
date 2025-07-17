class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]

  def new
    redirect_to root_path if user_signed_in?
  end

  def create
    if Rails.env.development? && params[:dev_login] == 'true'
      session[:current_user] = {
        uid: 'dev_user',
        email: 'dev@example.com',
        name: 'Development User',
        verified: true
      }
      redirect_to root_path, notice: 'Successfully logged in (Development Mode)'
    else
      # Firebase token authentication
      token = params[:firebase_token]
      if token && (user_info = ApplicationRecord.verify_firebase_token(token))
        session[:current_user] = user_info
        redirect_to root_path, notice: 'Successfully logged in'
      else
        redirect_to login_path, alert: 'Invalid authentication token'
      end
    end
  end

  def destroy
    sign_out_user
    redirect_to login_path, notice: 'Successfully logged out'
  end
end