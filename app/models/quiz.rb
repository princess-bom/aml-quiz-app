class Quiz
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :string
  attribute :question, :string
  attribute :score, :integer
  attribute :choices, default: []
  attribute :correct_answer, :string
  attribute :explanation, :string
  attribute :reference, :string
  attribute :difficulty, :string
  attribute :category, :string
  attribute :subject, :string
  attribute :question_type, :string
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  validates :question, presence: true
  validates :score, presence: true, inclusion: { in: [5, 10, 15] }
  validates :choices, presence: true, length: { is: 5 }
  validates :correct_answer, presence: true
  validates :explanation, presence: true
  validates :subject, presence: true, inclusion: { in: SUBJECTS }
  validates :question_type, presence: true, inclusion: { in: QUESTION_TYPES }
  validates :difficulty, presence: true, inclusion: { in: DIFFICULTY_LEVELS }

  # Constants for validation
  SUBJECTS = [
    "자금세탁방지 글로벌 기준",
    "국내 자금세탁방지 제도", 
    "고객확인의무",
    "고액현금거래·의심거래보고",
    "위험평가",
    "자금세탁방지 실무"
  ].freeze

  QUESTION_TYPES = %w[A B C].freeze
  DIFFICULTY_LEVELS = %w[상급 중상급 최상급].freeze

  class << self
    def collection
      return nil unless FIRESTORE
      FIRESTORE.collection('quizzes')
    end

    def all
      return sample_quizzes unless FIRESTORE
      collection.get.map { |doc| new(doc.data.merge(id: doc.document_id)) }
    end

    def find(id)
      return sample_quizzes.find { |quiz| quiz.id == id } unless FIRESTORE
      doc = collection.document(id).get
      return nil unless doc.exists?
      new(doc.data.merge(id: doc.document_id))
    end

    def random(limit = 1)
      all.sample(limit)
    end

    def by_difficulty(difficulty)
      return sample_quizzes.select { |quiz| quiz.difficulty == difficulty } unless FIRESTORE
      collection.where(:difficulty, :==, difficulty).get.map do |doc|
        new(doc.data.merge(id: doc.document_id))
      end
    end

    def by_category(category)
      return sample_quizzes.select { |quiz| quiz.category == category } unless FIRESTORE
      collection.where(:category, :==, category).get.map do |doc|
        new(doc.data.merge(id: doc.document_id))
      end
    end

    def by_subject(subject)
      return sample_quizzes.select { |quiz| quiz.subject == subject } unless FIRESTORE
      collection.where(:subject, :==, subject).get.map do |doc|
        new(doc.data.merge(id: doc.document_id))
      end
    end

    def by_question_type(question_type)
      return sample_quizzes.select { |quiz| quiz.question_type == question_type } unless FIRESTORE
      collection.where(:question_type, :==, question_type).get.map do |doc|
        new(doc.data.merge(id: doc.document_id))
      end
    end

    def by_subject_type_difficulty(subject, question_type, difficulty)
      return sample_quizzes.select { |quiz| 
        quiz.subject == subject && 
        quiz.question_type == question_type && 
        quiz.difficulty == difficulty 
      } unless FIRESTORE
      
      collection.where(:subject, :==, subject)
                .where(:question_type, :==, question_type)
                .where(:difficulty, :==, difficulty)
                .get.map do |doc|
        new(doc.data.merge(id: doc.document_id))
      end
    end

    def random_by_criteria(subject: nil, question_type: nil, difficulty: nil, limit: 20)
      quizzes = if FIRESTORE
        query = collection
        query = query.where(:subject, :==, subject) if subject
        query = query.where(:question_type, :==, question_type) if question_type
        query = query.where(:difficulty, :==, difficulty) if difficulty
        query.get.map { |doc| new(doc.data.merge(id: doc.document_id)) }
      else
        filtered_quizzes = sample_quizzes
        filtered_quizzes = filtered_quizzes.select { |q| q.subject == subject } if subject
        filtered_quizzes = filtered_quizzes.select { |q| q.question_type == question_type } if question_type
        filtered_quizzes = filtered_quizzes.select { |q| q.difficulty == difficulty } if difficulty
        filtered_quizzes
      end
      
      quizzes.sample(limit)
    end

    def create(attributes)
      quiz = new(attributes)
      return quiz unless quiz.valid?
      
      if FIRESTORE
        doc_ref = collection.add(quiz.to_hash)
        quiz.id = doc_ref.document_id
      else
        quiz.id = SecureRandom.uuid
      end
      quiz
    end

    private

    def sample_quizzes
      @sample_quizzes ||= [
        new(
          id: "quiz_1",
          question: "자금세탁방지법(AML)에서 규정하는 고객확인의무(CDD)에 대한 설명으로 옳은 것은?",
          score: 10,
          choices: [
            "고객확인은 계좌개설 시에만 수행하면 된다",
            "고객확인은 거래 금액에 관계없이 항상 동일한 수준으로 수행한다",
            "고객의 위험도에 따라 차등적으로 고객확인을 수행해야 한다",
            "고객확인은 법인 고객에게만 적용된다",
            "고객확인의무는 권고사항이므로 선택적으로 수행할 수 있다"
          ],
          correct_answer: "고객의 위험도에 따라 차등적으로 고객확인을 수행해야 한다",
          explanation: "자금세탁방지법에서는 위험기반접근법(RBA)을 채택하여 고객의 위험도에 따라 차등적으로 고객확인을 수행하도록 규정하고 있습니다. 고위험 고객에게는 강화된 고객확인(EDD)을, 저위험 고객에게는 간소화된 고객확인(SDD)을 적용할 수 있습니다.",
          reference: "자금세탁방지법 제4조, 제5조",
          difficulty: "중상급",
          category: "AML",
          subject: "고객확인의무",
          question_type: "A",
          created_at: Time.current,
          updated_at: Time.current
        ),
        new(
          id: "quiz_2",
          question: "의심거래보고(STR)에 대한 설명으로 옳지 않은 것은?",
          score: 15,
          choices: [
            "의심거래보고는 즉시 또는 지체없이 금융정보분석원(FIU)에 보고해야 한다",
            "의심거래보고 사실을 고객에게 통지해야 한다",
            "의심거래보고는 금융기관의 의무사항이다",
            "의심거래보고 대상은 자금세탁 의심거래와 테러자금조달 의심거래를 포함한다",
            "의심거래보고는 거래 금액에 관계없이 의심스러우면 보고해야 한다"
          ],
          correct_answer: "의심거래보고 사실을 고객에게 통지해야 한다",
          explanation: "의심거래보고 사실을 고객에게 통지하는 것은 금지되어 있습니다(티핑오프 금지). 이는 수사기관의 조사를 방해하고 증거인멸 등의 위험을 초래할 수 있기 때문입니다.",
          reference: "자금세탁방지법 제8조, 제9조",
          difficulty: "최상급",
          category: "AML",
          subject: "고액현금거래·의심거래보고",
          question_type: "B",
          created_at: Time.current,
          updated_at: Time.current
        ),
        new(
          id: "quiz_3",
          question: "FATF(Financial Action Task Force)에 대한 설명으로 옳은 것은?",
          score: 5,
          choices: [
            "FATF는 UN의 하위기관이다",
            "FATF는 자금세탁방지 국제기준을 제정하는 정부간 기구이다",
            "FATF는 각국의 금융감독기관을 총괄하는 기관이다",
            "FATF는 국제은행연합회의 별칭이다",
            "FATF는 미국의 금융정보분석원이다"
          ],
          correct_answer: "FATF는 자금세탁방지 국제기준을 제정하는 정부간 기구이다",
          explanation: "FATF(Financial Action Task Force)는 1989년 G7 정상회의에서 설립된 정부간 기구로, 자금세탁방지 및 테러자금조달 방지를 위한 국제기준을 제정하고 각국의 이행상황을 평가하는 역할을 합니다.",
          reference: "FATF 40 권고사항",
          difficulty: "상급",
          category: "AML",
          subject: "자금세탁방지 글로벌 기준",
          question_type: "A",
          created_at: Time.current,
          updated_at: Time.current
        )
      ]
    end
  end

  def save
    return false unless valid?
    
    if id
      collection.document(id).set(to_hash)
    else
      doc_ref = collection.add(to_hash)
      self.id = doc_ref.document_id
    end
    true
  end

  def update(attributes)
    attributes.each { |key, value| public_send("#{key}=", value) }
    save
  end

  def destroy
    return false unless id
    collection.document(id).delete
    true
  end

  def to_hash
    {
      question: question,
      score: score,
      choices: choices,
      correct_answer: correct_answer,
      explanation: explanation,
      reference: reference,
      difficulty: difficulty,
      category: category,
      subject: subject,
      question_type: question_type,
      created_at: created_at || Time.current,
      updated_at: Time.current
    }
  end

  def check_answer(user_answer)
    correct_answer == user_answer
  end

  def choice_label(index)
    ('A'..'E').to_a[index]
  end

  def correct_choice_index
    choices.index(correct_answer)
  end

  def correct_choice_label
    choice_label(correct_choice_index)
  end

  private

  def collection
    self.class.collection
  end
end