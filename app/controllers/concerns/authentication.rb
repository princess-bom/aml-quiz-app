module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    helper_method :current_user, :user_signed_in?
  end

  private

  def authenticate_user!
    return if user_signed_in?
    
    # For development, allow simple authentication
    if Rails.env.development? && params[:dev_auth] == 'true'
      session[:current_user] = {
        uid: 'dev_user',
        email: 'dev@example.com',
        name: 'Development User',
        verified: true
      }
      return
    end
    
    redirect_to login_path, alert: 'Please log in to continue.'
  end

  def current_user
    @current_user ||= begin
      if session[:current_user]
        session[:current_user]
      elsif firebase_token = request.headers['Authorization']&.gsub('Bearer ', '')
        user_info = ApplicationRecord.verify_firebase_token(firebase_token)
        if user_info
          session[:current_user] = user_info
          user_info
        else
          nil
        end
      else
        nil
      end
    end
  end

  def user_signed_in?
    current_user.present?
  end

  def sign_out_user
    session.delete(:current_user)
    @current_user = nil
  end
end