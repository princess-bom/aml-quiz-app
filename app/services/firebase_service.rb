require 'net/http'
require 'json'
require 'uri'

class FirebaseService
  attr_reader :project_id, :base_url
  
  def initialize
    config = Rails.application.config_for(:firebase)
    @project_id = config['project_id']
    @base_url = config['database_url']
  end
  
  # Questions CRUD operations
  def create_question(question_data)
    url = "#{@base_url}/questions/#{question_data[:id]}.json"
    make_request(:put, url, question_data)
  end
  
  def get_question(question_id)
    url = "#{@base_url}/questions/#{question_id}.json"
    make_request(:get, url)
  end
  
  def get_all_questions
    url = "#{@base_url}/questions.json"
    response = make_request(:get, url)
    
    return [] unless response
    
    # Convert Firebase object format to array
    questions = []
    response.each do |key, value|
      next unless value.is_a?(Hash)
      questions << value.merge(firebase_key: key)
    end
    
    questions
  end
  
  def get_questions_by_subject(subject_id)
    questions = get_all_questions
    questions.select { |q| q['subject_id'] == subject_id }
  end
  
  def get_questions_by_difficulty(difficulty)
    questions = get_all_questions
    questions.select { |q| q['difficulty'] == difficulty }
  end
  
  def get_questions_by_subject_and_difficulty(subject_id, difficulty)
    questions = get_all_questions
    questions.select { |q| q['subject_id'] == subject_id && q['difficulty'] == difficulty }
  end
  
  # Explanations CRUD operations
  def create_explanation(explanation_data)
    url = "#{@base_url}/explanations/#{explanation_data[:question_id]}.json"
    make_request(:put, url, explanation_data)
  end
  
  def get_explanation(question_id)
    url = "#{@base_url}/explanations/#{question_id}.json"
    make_request(:get, url)
  end
  
  def get_all_explanations
    url = "#{@base_url}/explanations.json"
    response = make_request(:get, url)
    
    return [] unless response
    
    # Convert Firebase object format to array
    explanations = []
    response.each do |key, value|
      next unless value.is_a?(Hash)
      explanations << value.merge(firebase_key: key)
    end
    
    explanations
  end
  
  # User quiz sessions and statistics
  def create_quiz_session(user_id, session_data)
    timestamp = Time.current.to_i
    url = "#{@base_url}/users/#{user_id}/quiz_sessions/#{timestamp}.json"
    session_data = session_data.merge(created_at: timestamp)
    make_request(:put, url, session_data)
  end
  
  def get_user_quiz_sessions(user_id)
    url = "#{@base_url}/users/#{user_id}/quiz_sessions.json"
    response = make_request(:get, url)
    
    return [] unless response
    
    sessions = []
    response.each do |key, value|
      next unless value.is_a?(Hash)
      sessions << value.merge(session_id: key)
    end
    
    sessions
  end
  
  def update_user_stats(user_id, stats_data)
    url = "#{@base_url}/users/#{user_id}/stats.json"
    make_request(:patch, url, stats_data)
  end
  
  def get_user_stats(user_id)
    url = "#{@base_url}/users/#{user_id}/stats.json"
    make_request(:get, url)
  end
  
  # User answers and wrong answers tracking
  def save_user_answer(user_id, session_id, answer_data)
    timestamp = Time.current.to_i
    url = "#{@base_url}/users/#{user_id}/answers/#{session_id}/#{answer_data[:question_id]}.json"
    answer_data = answer_data.merge(answered_at: timestamp)
    make_request(:put, url, answer_data)
  end
  
  def save_wrong_answer(user_id, wrong_answer_data)
    timestamp = Time.current.to_i
    url = "#{@base_url}/users/#{user_id}/wrong_answers/#{timestamp}.json"
    wrong_answer_data = wrong_answer_data.merge(created_at: timestamp)
    make_request(:put, url, wrong_answer_data)
  end
  
  def get_user_wrong_answers(user_id)
    url = "#{@base_url}/users/#{user_id}/wrong_answers.json"
    response = make_request(:get, url)
    
    return [] unless response
    
    wrong_answers = []
    response.each do |key, value|
      next unless value.is_a?(Hash)
      wrong_answers << value.merge(wrong_answer_id: key)
    end
    
    wrong_answers
  end
  
  # Bulk operations for seeding
  def bulk_upload_questions(questions_array)
    questions_hash = {}
    questions_array.each do |question|
      questions_hash[question[:id]] = question
    end
    
    url = "#{@base_url}/questions.json"
    make_request(:put, url, questions_hash)
  end
  
  def bulk_upload_explanations(explanations_array)
    explanations_hash = {}
    explanations_array.each do |explanation|
      explanations_hash[explanation[:question_id]] = explanation
    end
    
    url = "#{@base_url}/explanations.json"
    make_request(:put, url, explanations_hash)
  end
  
  # Clear all data (for testing/development)
  def clear_all_data
    make_request(:delete, "#{@base_url}/questions.json")
    make_request(:delete, "#{@base_url}/explanations.json")
    make_request(:delete, "#{@base_url}/users.json")
  end
  
  private
  
  def make_request(method, url, data = nil)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    case method
    when :get
      request = Net::HTTP::Get.new(uri)
    when :post
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = data.to_json if data
    when :put
      request = Net::HTTP::Put.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = data.to_json if data
    when :patch
      request = Net::HTTP::Patch.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = data.to_json if data
    when :delete
      request = Net::HTTP::Delete.new(uri)
    end
    
    begin
      response = http.request(request)
      
      case response.code.to_i
      when 200..299
        response.body.present? ? JSON.parse(response.body) : true
      when 404
        nil
      else
        Rails.logger.error "Firebase request failed: #{response.code} - #{response.body}"
        raise "Firebase request failed: #{response.code}"
      end
    rescue JSON::ParserError => e
      Rails.logger.error "Firebase JSON parsing error: #{e.message}"
      raise "Firebase response parsing failed"
    rescue => e
      Rails.logger.error "Firebase request error: #{e.message}"
      raise "Firebase connection failed: #{e.message}"
    end
  end
end