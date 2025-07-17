Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication routes
  get "login" => "sessions#new", as: :login
  post "login" => "sessions#create"
  delete "logout" => "sessions#destroy", as: :logout

  # Quiz selection routes
  get "quiz_selection" => "quiz_selection#index", as: :quiz_selection
  get "quiz_selection/:subject" => "quiz_selection#show_subject", as: :quiz_selection_subject
  post "quiz_selection/start" => "quiz_selection#start_quiz", as: :start_quiz
  get "quiz_selection/recommended" => "quiz_selection#recommended", as: :recommended_quizzes

  # Quiz routes
  resources :quizzes, only: [:show, :new, :create] do
    member do
      post :answer
    end
  end

  # Quiz results routes
  resources :quiz_results, only: [:show]

  # Wrong answers routes
  resources :wrong_answers do
    member do
      patch :toggle_bookmark
      patch :update_note
      post :retry_quiz
    end
    
    collection do
      post :bulk_retry
      get :export
      get :analytics
    end
  end

  # Learning analytics routes
  get "analytics" => "analytics#index", as: :analytics
  get "analytics/subjects/:subject" => "analytics#subject", as: :subject_analytics

  # Root route
  root "home#index"
end
