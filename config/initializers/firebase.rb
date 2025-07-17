require 'google/cloud/firestore'

# Check if Firebase service account file exists
service_account_path = Rails.root.join('config', 'firebase', 'service_account.json')
firebase_configured = false

begin
  if Rails.env.production?
    # Production: Use service account key from environment variable
    if ENV['FIREBASE_PROJECT_ID'] && ENV['FIREBASE_SERVICE_ACCOUNT_KEY']
      Google::Cloud::Firestore.configure do |config|
        config.project_id = ENV['FIREBASE_PROJECT_ID']
        config.credentials = JSON.parse(ENV['FIREBASE_SERVICE_ACCOUNT_KEY'])
      end
      firebase_configured = true
    end
  else
    # Development: Use service account key file
    if File.exist?(service_account_path) && ENV['FIREBASE_PROJECT_ID']
      Google::Cloud::Firestore.configure do |config|
        config.project_id = ENV['FIREBASE_PROJECT_ID']
        config.credentials = service_account_path
      end
      firebase_configured = true
    end
  end

  # Initialize Firestore client only if configured
  if firebase_configured
    FIRESTORE = Google::Cloud::Firestore.new
    Rails.logger.info "Firebase Firestore initialized successfully"
  else
    # Mock Firestore for development without Firebase
    FIRESTORE = nil
    Rails.logger.warn "Firebase not configured. Running in development mode without Firebase."
  end
rescue => e
  Rails.logger.error "Firebase initialization failed: #{e.message}"
  FIRESTORE = nil
end