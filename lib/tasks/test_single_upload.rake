require 'csv'

namespace :firebase do
  desc "Test upload single text file"
  task test_single_upload: :environment do
    puts "🔥 Testing single file upload..."
    
    firebase_service = FirebaseService.new
    test_file = "/Users/cooljean/Desktop/AML/aml_quiz_app/quiz/과목 1/A-상.txt"
    
    puts "📄 Processing: #{test_file}"
    
    begin
      # 파일 읽기
      file_content = File.read(test_file, encoding: 'UTF-8')
      file_content = file_content.gsub(/\A\uFEFF/, '')
      
      lines = file_content.lines
      
      # Questions과 Explanations 구분
      explanations_start_idx = lines.find_index { |line| line.start_with?('question_id') }
      
      if explanations_start_idx
        questions_lines = lines[0...explanations_start_idx].reject { |line| line.strip.empty? }
        explanations_lines = lines[explanations_start_idx..-1]
      else
        questions_lines = lines
        explanations_lines = []
      end
      
      puts "📊 Found #{questions_lines.count - 1} questions (excluding header)"
      puts "📊 Found #{explanations_lines.count - 1} explanations (excluding header)"
      
      # Questions 처리 (첫 3개만 테스트)
      questions_csv = questions_lines.join
      question_count = 0
      
      CSV.parse(questions_csv, headers: true) do |row|
        break if question_count >= 3 # 첫 3개만 테스트
        next if row['id'].nil? || row['id'].to_s.strip.empty?
        
        question_data = {
          id: row['id'].to_i,
          subject_id: row['subject_id'].to_i,
          subject_name: row['subject_name'],
          source_type: row['source_type'],
          difficulty: row['difficulty'] == '상' ? 'high' : row['difficulty'],
          points: row['points']&.to_i || 15,
          question_type: row['question_type'],
          question_text: row['question_text'],
          option_1: row['option_1'],
          option_2: row['option_2'], 
          option_3: row['option_3'],
          option_4: row['option_4'],
          option_5: row['option_5'],
          correct_answer: row['correct_answer'],
          created_date: row['created_date']
        }
        
        puts "📝 Uploading question #{question_data[:id]}: #{question_data[:subject_name]}"
        firebase_service.create_question(question_data)
        question_count += 1
        
        puts "✅ Question #{question_data[:id]} uploaded successfully"
      end
      
      puts "\n🎉 Test upload completed!"
      puts "📊 Uploaded #{question_count} questions"
      
    rescue => e
      puts "❌ Error: #{e.message}"
      puts "📍 #{e.backtrace.first}"
    end
  end
end