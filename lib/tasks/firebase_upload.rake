require 'csv'

namespace :firebase do
  desc "Upload CSV quiz data to Firebase"
  task upload_quiz_data: :environment do
    puts "🔥 Starting Firebase upload process..."
    
    # Firebase configuration
    firebase_service = FirebaseService.new
    
    # CSV base path
    csv_base_path = "/Users/cooljean/Desktop/TPAC"
    
    unless Dir.exist?(csv_base_path)
      puts "❌ CSV path not found: #{csv_base_path}"
      exit 1
    end
    
    # Subject mapping
    subjects = {
      1 => "자금세탁방지법",
      2 => "고객확인제도", 
      3 => "의심거래신고",
      4 => "고객관리",
      5 => "내부통제",
      6 => "금융감독"
    }
    
    # Difficulty mapping
    difficulty_mapping = {
      "상" => "high",
      "중상" => "medium_high", 
      "최상" => "highest"
    }
    
    uploaded_questions = 0
    uploaded_explanations = 0
    
    subjects.each do |subject_id, subject_name|
      subject_path = File.join(csv_base_path, "과목 #{subject_id}")
      next unless Dir.exist?(subject_path)
      
      puts "📚 Processing Subject #{subject_id}: #{subject_name}"
      
      ["상", "중상", "최상"].each do |difficulty_ko|
        difficulty_en = difficulty_mapping[difficulty_ko]
        
        # Process Questions
        questions_file = File.join(subject_path, "A-#{difficulty_ko}_questions.csv")
        if File.exist?(questions_file)
          puts "  📄 Uploading questions: A-#{difficulty_ko}_questions.csv"
          
          begin
            # Read CSV with proper encoding handling
            csv_content = File.read(questions_file, encoding: 'UTF-8')
            # Remove BOM if present
            csv_content = csv_content.gsub(/\A\uFEFF/, '')
            
            CSV.parse(csv_content, headers: true) do |row|
              next if row['id'].nil? || row['id'].to_s.strip.empty?
              
              question_data = {
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
                created_date: row['created_date'] || Date.current.to_s
              }
              
              # Upload to Firebase
              firebase_service.create_question(question_data)
              uploaded_questions += 1
              
              print "."
            end
            puts " ✅"
          rescue => e
            puts "    ❌ Error processing questions: #{e.message}"
          end
        end
        
        # Process Explanations
        explanations_file = File.join(subject_path, "A-#{difficulty_ko}_explanations.csv")
        if File.exist?(explanations_file)
          puts "  💡 Uploading explanations: A-#{difficulty_ko}_explanations.csv"
          
          begin
            csv_content = File.read(explanations_file, encoding: 'UTF-8')
            csv_content = csv_content.gsub(/\A\uFEFF/, '')
            
            CSV.parse(csv_content, headers: true) do |row|
              next if row['question_id'].nil? || row['question_id'].to_s.strip.empty?
              
              explanation_data = {
                question_id: row['question_id'].to_i,
                correct_reason: row['correct_reason'],
                wrong_reason_1: row['wrong_reason_1'],
                wrong_reason_2: row['wrong_reason_2'],
                wrong_reason_3: row['wrong_reason_3'],
                wrong_reason_4: row['wrong_reason_4'],
                key_point: row['key_point'],
                reference: row['reference'],
                learning_objective: row['learning_objective']
              }
              
              # Upload to Firebase
              firebase_service.create_explanation(explanation_data)
              uploaded_explanations += 1
              
              print "."
            end
            puts " ✅"
          rescue => e
            puts "    ❌ Error processing explanations: #{e.message}"
          end
        end
      end
    end
    
    puts "\n🎉 Upload completed!"
    puts "📊 Summary:"
    puts "  - Questions uploaded: #{uploaded_questions}"
    puts "  - Explanations uploaded: #{uploaded_explanations}"
  end
  
  desc "Download quiz data from Firebase to local database"
  task download_quiz_data: :environment do
    puts "📥 Downloading quiz data from Firebase..."
    
    firebase_service = FirebaseService.new
    
    # Clear existing data
    puts "Clearing existing local data..."
    Explanation.delete_all
    Question.delete_all
    
    # Download questions
    questions_data = firebase_service.get_all_questions
    questions_count = 0
    
    questions_data.each do |question_data|
      Question.create!(question_data)
      questions_count += 1
    end
    
    # Download explanations  
    explanations_data = firebase_service.get_all_explanations
    explanations_count = 0
    
    explanations_data.each do |explanation_data|
      Explanation.create!(explanation_data)
      explanations_count += 1
    end
    
    puts "✅ Download completed!"
    puts "📊 Summary:"
    puts "  - Questions downloaded: #{questions_count}"
    puts "  - Explanations downloaded: #{explanations_count}"
  end
end