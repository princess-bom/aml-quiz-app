# AML Quiz App Seeds
require 'csv'

puts "🌱 Starting to seed AML Quiz data..."

# Clear existing data
puts "Clearing existing data..."
UserAnswer.delete_all
WrongAnswer.delete_all
QuizSession.delete_all
Explanation.delete_all
Question.delete_all
User.delete_all

puts "✅ Data cleared"

# Subject mapping
SUBJECTS = {
  1 => "자금세탁방지법",
  2 => "고객확인제도", 
  3 => "의심거래신고",
  4 => "고객관리",
  5 => "내부통제",
  6 => "금융감독"
}

# Difficulty mapping
DIFFICULTY_MAPPING = {
  "상" => "high",
  "중상" => "medium_high", 
  "최상" => "highest"
}

# Load CSV data for each subject and difficulty
def load_quiz_data(base_path)
  questions_loaded = 0
  explanations_loaded = 0
  
  SUBJECTS.each do |subject_id, subject_name|
    subject_path = File.join(base_path, "과목 #{subject_id}")
    next unless Dir.exist?(subject_path)
    
    puts "📚 Loading Subject #{subject_id}: #{subject_name}"
    
    # Load different difficulty levels
    ["상", "중상", "최상"].each do |difficulty_ko|
      difficulty_en = DIFFICULTY_MAPPING[difficulty_ko]
      
      # Load Questions
      questions_file = File.join(subject_path, "A-#{difficulty_ko}_questions.csv")
      if File.exist?(questions_file)
        puts "  📄 Loading questions: A-#{difficulty_ko}_questions.csv"
        
        CSV.foreach(questions_file, headers: true, encoding: 'UTF-8') do |row|
          next if row['id'].nil? || row['id'].strip.empty?
          
          puts "    Processing question ID: #{row['id']}"
          
          Question.create!(
            id: row['id'].to_i,
            subject_id: subject_id,
            subject_name: subject_name,
            source_type: row['source_type'] || 'A',
            difficulty: difficulty_en,
            points: row['points']&.to_i || 15,
            question_type: row['question_type'] || 'multiple_choice',
            question_text: row['question_text'],
            option_1: row['option_1'],
            option_2: row['option_2'], 
            option_3: row['option_3'],
            option_4: row['option_4'],
            option_5: row['option_5'],
            correct_answer: row['correct_answer'],
            created_date: Date.parse(row['created_date'] || Date.current.to_s)
          )
          questions_loaded += 1
        end
      end
      
      # Load Explanations
      explanations_file = File.join(subject_path, "A-#{difficulty_ko}_explanations.csv")
      if File.exist?(explanations_file)
        puts "  💡 Loading explanations: A-#{difficulty_ko}_explanations.csv"
        
        CSV.foreach(explanations_file, headers: true, encoding: 'UTF-8') do |row|
          next if row['question_id'].nil? || row['question_id'].strip.empty?
          
          Explanation.create!(
            question_id: row['question_id'].to_i,
            correct_reason: row['correct_reason'],
            wrong_reason_1: row['wrong_reason_1'],
            wrong_reason_2: row['wrong_reason_2'],
            wrong_reason_3: row['wrong_reason_3'],
            wrong_reason_4: row['wrong_reason_4'],
            key_point: row['key_point'],
            reference: row['reference'],
            learning_objective: row['learning_objective']
          )
          explanations_loaded += 1
        end
      end
    end
  end
  
  puts "✅ Questions loaded: #{questions_loaded}"
  puts "✅ Explanations loaded: #{explanations_loaded}"
end

# Create sample users
puts "👥 Creating sample users..."
users = [
  {
    email: "test@example.com",
    name: "김민수",
    firebase_uid: "test_user_1",
    total_sessions: 24,
    average_score: 78.5,
    study_streak: 7
  },
  {
    email: "student@example.com", 
    name: "이영희",
    firebase_uid: "test_user_2",
    total_sessions: 15,
    average_score: 85.0,
    study_streak: 3
  }
]

users.each do |user_data|
  User.create!(user_data)
end

puts "✅ Users created: #{users.count}"

# Load quiz data from CSV files
csv_base_path = "/Users/cooljean/Desktop/TPAC"
if Dir.exist?(csv_base_path)
  load_quiz_data(csv_base_path)
else
  puts "⚠️  CSV path not found: #{csv_base_path}"
  puts "Creating sample questions instead..."
  
  # Create sample questions if CSV not available
  sample_questions = [
    {
      id: 1,
      subject_id: 1,
      subject_name: "자금세탁방지법",
      source_type: "A",
      difficulty: "high",
      points: 15,
      question_type: "multiple_choice",
      question_text: "자금세탁방지법상 고객확인 의무를 이행해야 하는 거래 기준 금액은?",
      option_1: "300만원 이상",
      option_2: "500만원 이상", 
      option_3: "1000만원 이상",
      option_4: "3000만원 이상",
      option_5: "5000만원 이상",
      correct_answer: "3",
      created_date: Date.current
    },
    {
      id: 2,
      subject_id: 2,
      subject_name: "고객확인제도",
      source_type: "A", 
      difficulty: "medium_high",
      points: 10,
      question_type: "multiple_choice",
      question_text: "고객확인제도에서 요구되는 신분확인 방법으로 올바른 것은?",
      option_1: "신분증 확인",
      option_2: "전화 확인",
      option_3: "이메일 확인", 
      option_4: "계좌번호만 확인",
      option_5: nil,
      correct_answer: "1",
      created_date: Date.current
    }
  ]
  
  sample_questions.each do |q|
    Question.create!(q)
    
    # Create sample explanation
    Explanation.create!(
      question_id: q[:id],
      correct_reason: "이것이 정답인 이유입니다.",
      wrong_reason_1: "첫 번째 오답 해설",
      wrong_reason_2: "두 번째 오답 해설", 
      wrong_reason_3: "세 번째 오답 해설",
      wrong_reason_4: "네 번째 오답 해설",
      key_point: "핵심 포인트",
      reference: "관련 법조문",
      learning_objective: "학습 목표"
    )
  end
  
  puts "✅ Sample questions created: #{sample_questions.count}"
end

puts "🎉 Seeding completed!"
puts "📊 Final counts:"
puts "  - Users: #{User.count}"
puts "  - Questions: #{Question.count}"
puts "  - Explanations: #{Explanation.count}"
puts "  - Quiz Sessions: #{QuizSession.count}"