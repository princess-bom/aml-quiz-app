class WrongAnswer
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :string
  attribute :user_id, :string
  attribute :quiz_id, :string
  attribute :user_answer, :string
  attribute :correct_answer, :string
  attribute :question, :string
  attribute :choices, default: []
  attribute :explanation, :string
  attribute :reference, :string
  attribute :subject, :string
  attribute :question_type, :string
  attribute :difficulty, :string
  attribute :user_note, :string
  attribute :bookmarked, :boolean, default: false
  attribute :retry_count, :integer, default: 0
  attribute :last_retry_correct, :boolean, default: false
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  validates :user_id, presence: true
  validates :quiz_id, presence: true
  validates :user_answer, presence: true
  validates :correct_answer, presence: true
  validates :question, presence: true
  validates :subject, presence: true
  validates :question_type, presence: true
  validates :difficulty, presence: true

  class << self
    def collection
      return nil unless FIRESTORE
      FIRESTORE.collection('wrong_answers')
    end

    def find(id)
      if FIRESTORE
        doc = collection.document(id).get
        return nil unless doc.exists?
        new(doc.data.merge(id: doc.document_id))
      else
        # Development mode - use Rails cache
        cached_data = Rails.cache.read("wrong_answer_#{id}")
        cached_data ? new(cached_data.merge(id: id)) : nil
      end
    end

    def find_by_user(user_id)
      if FIRESTORE
        collection.where(:user_id, :==, user_id)
                  .order_by(:created_at, :desc)
                  .get
                  .map { |doc| new(doc.data.merge(id: doc.document_id)) }
      else
        # Development mode - search through cache
        cached_ids = Rails.cache.read("user_wrong_answers_#{user_id}") || []
        cached_ids.map { |id| find(id) }.compact
      end
    end

    def find_by_user_and_subject(user_id, subject)
      if FIRESTORE
        collection.where(:user_id, :==, user_id)
                  .where(:subject, :==, subject)
                  .order_by(:created_at, :desc)
                  .get
                  .map { |doc| new(doc.data.merge(id: doc.document_id)) }
      else
        find_by_user(user_id).select { |wa| wa.subject == subject }
      end
    end

    def find_by_user_and_filters(user_id, filters = {})
      wrong_answers = find_by_user(user_id)
      
      wrong_answers = wrong_answers.select { |wa| wa.subject == filters[:subject] } if filters[:subject]
      wrong_answers = wrong_answers.select { |wa| wa.question_type == filters[:question_type] } if filters[:question_type]
      wrong_answers = wrong_answers.select { |wa| wa.difficulty == filters[:difficulty] } if filters[:difficulty]
      wrong_answers = wrong_answers.select { |wa| wa.bookmarked } if filters[:bookmarked]
      
      if filters[:search]
        search_term = filters[:search].downcase
        wrong_answers = wrong_answers.select do |wa|
          wa.question.downcase.include?(search_term) || 
          wa.user_note&.downcase&.include?(search_term) ||
          wa.explanation.downcase.include?(search_term)
        end
      end
      
      wrong_answers
    end

    def create_from_quiz_session(user_id, quiz, user_answer)
      wrong_answer = new(
        user_id: user_id,
        quiz_id: quiz.id,
        user_answer: user_answer,
        correct_answer: quiz.correct_answer,
        question: quiz.question,
        choices: quiz.choices,
        explanation: quiz.explanation,
        reference: quiz.reference,
        subject: quiz.subject,
        question_type: quiz.question_type,
        difficulty: quiz.difficulty,
        created_at: Time.current
      )
      
      wrong_answer.save
      wrong_answer
    end

    def user_statistics(user_id)
      wrong_answers = find_by_user(user_id)
      
      {
        total_count: wrong_answers.count,
        by_subject: wrong_answers.group_by(&:subject).transform_values(&:count),
        by_question_type: wrong_answers.group_by(&:question_type).transform_values(&:count),
        by_difficulty: wrong_answers.group_by(&:difficulty).transform_values(&:count),
        bookmarked_count: wrong_answers.count(&:bookmarked),
        retry_count: wrong_answers.sum(&:retry_count),
        improvement_rate: calculate_improvement_rate(wrong_answers)
      }
    end

    private

    def calculate_improvement_rate(wrong_answers)
      retried_answers = wrong_answers.select { |wa| wa.retry_count > 0 }
      return 0 if retried_answers.empty?
      
      correct_retries = retried_answers.count(&:last_retry_correct)
      (correct_retries.to_f / retried_answers.count * 100).round(1)
    end
  end

  def save
    self.id ||= SecureRandom.uuid
    self.updated_at = Time.current
    
    if FIRESTORE
      collection.document(id).set(to_hash)
    else
      # Development mode - use Rails cache
      Rails.cache.write("wrong_answer_#{id}", to_hash, expires_in: 1.week)
      
      # Update user's wrong answers list
      user_wrong_answers = Rails.cache.read("user_wrong_answers_#{user_id}") || []
      user_wrong_answers.unshift(id) unless user_wrong_answers.include?(id)
      user_wrong_answers = user_wrong_answers.first(100) # Keep only last 100
      Rails.cache.write("user_wrong_answers_#{user_id}", user_wrong_answers, expires_in: 1.week)
    end
    
    true
  end

  def update_note(note)
    self.user_note = note
    save
  end

  def toggle_bookmark
    self.bookmarked = !bookmarked
    save
  end

  def record_retry(correct)
    self.retry_count += 1
    self.last_retry_correct = correct
    save
  end

  def to_hash
    {
      user_id: user_id,
      quiz_id: quiz_id,
      user_answer: user_answer,
      correct_answer: correct_answer,
      question: question,
      choices: choices,
      explanation: explanation,
      reference: reference,
      subject: subject,
      question_type: question_type,
      difficulty: difficulty,
      user_note: user_note,
      bookmarked: bookmarked,
      retry_count: retry_count,
      last_retry_correct: last_retry_correct,
      created_at: created_at || Time.current,
      updated_at: updated_at || Time.current
    }
  end

  def quiz
    @quiz ||= Quiz.find(quiz_id)
  end

  def user_choice_index
    choices.index(user_answer)
  end

  def correct_choice_index
    choices.index(correct_answer)
  end

  def user_choice_label
    return nil unless user_choice_index
    ('A'..'E').to_a[user_choice_index]
  end

  def correct_choice_label
    return nil unless correct_choice_index
    ('A'..'E').to_a[correct_choice_index]
  end

  def difficulty_color
    case difficulty
    when '상급' then 'text-green-600'
    when '중상급' then 'text-yellow-600'
    when '최상급' then 'text-red-600'
    else 'text-gray-600'
    end
  end

  def subject_color
    case subject
    when '자금세탁방지 글로벌 기준' then 'text-blue-600'
    when '국내 자금세탁방지 제도' then 'text-purple-600'
    when '고객확인의무' then 'text-green-600'
    when '고액현금거래·의심거래보고' then 'text-orange-600'
    when '위험평가' then 'text-red-600'
    when '자금세탁방지 실무' then 'text-indigo-600'
    else 'text-gray-600'
    end
  end

  private

  def collection
    self.class.collection
  end
end