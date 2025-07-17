module FirebaseAuth
  extend ActiveSupport::Concern

  class_methods do
    def verify_firebase_token(token)
      begin
        decoded_token = JWT.decode(token, nil, false)
        payload = decoded_token[0]
        
        # Basic validation
        return nil unless payload['aud'] == ENV['FIREBASE_PROJECT_ID']
        return nil unless payload['iss'] == "https://securetoken.google.com/#{ENV['FIREBASE_PROJECT_ID']}"
        return nil unless payload['exp'] > Time.current.to_i
        
        # Return user info from token
        {
          uid: payload['sub'],
          email: payload['email'],
          name: payload['name'],
          verified: payload['email_verified']
        }
      rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::InvalidIssuerError, JWT::InvalidAudienceError
        nil
      end
    end
  end
end