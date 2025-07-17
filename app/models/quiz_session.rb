class QuizSession
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :string
  attribute :user_id, :string
  attribute :quiz_ids, default: []
  attribute :current_quiz_index, :integer, default: 0
  attribute :answers, default: []
  attribute :score, :integer, default: 0
  attribute :total_questions, :integer
  attribute :correct_answers, :integer, default: 0
  attribute :started_at, :datetime
  attribute :completed_at, :datetime
  attribute :status, :string, default: 'active'
  attribute :updated_at, :datetime

  validates :user_id, presence: true
  validates :quiz_ids, presence: true

  class << self
    def collection
      return nil unless FIRESTORE
      FIRESTORE.collection('quiz_sessions')
    end

    def find(id)
      if FIRESTORE
        doc = collection.document(id).get
        return nil unless doc.exists?
        new(doc.data.merge(id: doc.document_id))
      else
        # In development mode without Firebase, use session storage
        session_data = Rails.cache.read("quiz_session_#{id}")
        session_data ? new(session_data.merge(id: id)) : nil
      end
    end

    def find_by_user(user_id)
      if FIRESTORE
        collection.where(:user_id, :==, user_id)
                  .where(:status, :==, 'active')
                  .get
                  .map { |doc| new(doc.data.merge(id: doc.document_id)) }
                  .first
      else
        # In development mode, check cache
        cached_session_id = Rails.cache.read("active_session_#{user_id}")
        cached_session_id ? find(cached_session_id) : nil
      end
    end

    def create_for_user(user_id, quiz_count = 3)
      quizzes = Quiz.random(quiz_count)
      quiz_ids = quizzes.map(&:id)
      
      session = new(
        id: SecureRandom.uuid,
        user_id: user_id,
        quiz_ids: quiz_ids,
        total_questions: quiz_count,
        started_at: Time.current,
        status: 'active'
      )
      
      session.save
      session
    end
  end

  def save
    return false unless valid?
    
    if FIRESTORE
      if id
        collection.document(id).set(to_hash)
      else
        doc_ref = collection.add(to_hash)
        self.id = doc_ref.document_id
      end
    else
      # In development mode without Firebase, use Rails cache
      self.id ||= SecureRandom.uuid
      Rails.cache.write("quiz_session_#{id}", to_hash, expires_in: 1.hour)
      Rails.cache.write("active_session_#{user_id}", id, expires_in: 1.hour) if status == 'active'
    end
    true
  end

  def current_quiz
    return nil if completed? || current_quiz_index >= quiz_ids.length
    Quiz.find(quiz_ids[current_quiz_index])
  end

  def submit_answer(answer)
    return false if completed?
    
    current_quiz_obj = current_quiz
    return false unless current_quiz_obj
    
    is_correct = current_quiz_obj.check_answer(answer)
    
    # Record answer
    self.answers << {
      quiz_id: current_quiz_obj.id,
      user_answer: answer,
      correct_answer: current_quiz_obj.correct_answer,
      is_correct: is_correct,
      score: is_correct ? current_quiz_obj.score : 0,
      answered_at: Time.current
    }
    
    # Update counters
    if is_correct
      self.correct_answers += 1
      self.score += current_quiz_obj.score
    end
    
    # Move to next question
    self.current_quiz_index += 1
    
    # Check if session is complete
    if current_quiz_index >= quiz_ids.length
      self.status = 'completed'
      self.completed_at = Time.current
    end
    
    save
    is_correct
  end

  def completed?
    status == 'completed'
  end

  def progress_percentage
    return 0 if total_questions == 0
    ((current_quiz_index.to_f / total_questions) * 100).round
  end

  def accuracy_percentage
    return 0 if answers.empty?
    ((correct_answers.to_f / answers.length) * 100).round
  end

  def remaining_questions
    total_questions - current_quiz_index
  end

  def total_possible_score
    quiz_ids.map { |id| Quiz.find(id)&.score || 0 }.sum
  end

  def score_percentage
    return 0 if total_possible_score == 0
    ((score.to_f / total_possible_score) * 100).round
  end

  def session_duration
    return nil unless started_at
    end_time = completed_at || Time.current
    end_time - started_at
  end

  def to_hash
    {
      user_id: user_id,
      quiz_ids: quiz_ids,
      current_quiz_index: current_quiz_index,
      answers: answers,
      score: score,
      total_questions: total_questions,
      correct_answers: correct_answers,
      started_at: started_at,
      completed_at: completed_at,
      status: status,
      updated_at: Time.current
    }
  end

  private

  def collection
    self.class.collection
  end
end