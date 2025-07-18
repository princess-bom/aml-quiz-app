require 'csv'

namespace :firebase do
  desc "Upload text files (CSV format) to Firebase with correct subject mapping"
  task upload_text_files: :environment do
    puts "🔥 Starting text file upload to Firebase..."
    
    # Firebase service
    firebase_service = FirebaseService.new
    
    # 텍스트 파일 베이스 경로
    text_base_path = "/Users/cooljean/Desktop/AML/aml_quiz_app/quiz"
    
    unless Dir.exist?(text_base_path)
      puts "❌ Text files path not found: #{text_base_path}"
      exit 1
    end
    
    # PRD 기준 과목 매핑
    subjects = {
      1 => "자금세탁방지 글로벌 기준",
      2 => "국내 자금세탁방지 제도", 
      3 => "고객확인의무",
      4 => "고액현금거래·의심거래보고",
      5 => "위험평가",
      6 => "자금세탁방지 실무"
    }
    
    # 난이도 매핑
    difficulty_mapping = {
      "상" => "high",
      "중상" => "medium_high", 
      "최상" => "highest"
    }
    
    uploaded_questions = 0
    uploaded_explanations = 0
    
    subjects.each do |subject_id, subject_name|
      subject_path = File.join(text_base_path, "과목 #{subject_id}")
      next unless Dir.exist?(subject_path)
      
      puts "📚 Processing Subject #{subject_id}: #{subject_name}"
      
      # A, B, C 타입별로 처리
      ["A", "B", "C"].each do |source_type|
        # 상, 중상, 최상 난이도별로 처리
        ["상", "중상", "최상"].each do |difficulty_ko|
          difficulty_en = difficulty_mapping[difficulty_ko]
          
          # 텍스트 파일 경로
          text_file = File.join(subject_path, "#{source_type}-#{difficulty_ko}.txt")
          next unless File.exist?(text_file)
          
          puts "  📄 Processing: #{source_type}-#{difficulty_ko}.txt"
          
          begin
            # 파일 읽기 (UTF-8 BOM 처리)
            file_content = File.read(text_file, encoding: 'UTF-8')
            file_content = file_content.gsub(/\A\uFEFF/, '') # BOM 제거
            
            # CSV 데이터 분리
            lines = file_content.lines
            
            # Questions과 Explanations 구분 찾기
            questions_end_idx = lines.find_index { |line| line.strip.empty? || line.start_with?('question_id') }
            
            if questions_end_idx.nil?
              puts "    ⚠️  No explanations section found, treating all as questions"
              questions_lines = lines
              explanations_lines = []
            else
              questions_lines = lines[0...questions_end_idx]
              explanations_lines = lines[questions_end_idx..-1].select { |line| !line.strip.empty? }
            end
            
            # Questions 처리
            if questions_lines.any?
              questions_csv = questions_lines.join
              
              CSV.parse(questions_csv, headers: true) do |row|
                next if row['id'].nil? || row['id'].to_s.strip.empty?
                
                question_data = {
                  id: row['id'].to_i,
                  subject_id: subject_id, # 폴더 기준으로 수정
                  subject_name: subject_name, # PRD 기준으로 수정
                  source_type: source_type, # 파일명에서 추출
                  difficulty: difficulty_en, # 파일명에서 추출
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
                
                # Firebase에 업로드
                firebase_service.create_question(question_data)
                uploaded_questions += 1
                
                print "."
              end
              puts " ✅ Questions uploaded"
            end
            
            # Explanations 처리
            if explanations_lines.any?
              explanations_csv = explanations_lines.join
              
              CSV.parse(explanations_csv, headers: true) do |row|
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
                
                # Firebase에 업로드
                firebase_service.create_explanation(explanation_data)
                uploaded_explanations += 1
                
                print "."
              end
              puts " ✅ Explanations uploaded"
            end
            
          rescue => e
            puts "    ❌ Error processing #{text_file}: #{e.message}"
            puts "    📍 Error details: #{e.backtrace.first}"
          end
        end
      end
    end
    
    puts "\n🎉 Text file upload completed!"
    puts "📊 Summary:"
    puts "  - Questions uploaded: #{uploaded_questions}"
    puts "  - Explanations uploaded: #{uploaded_explanations}"
    puts "  - Subjects processed: 1-4 (5-6 not ready)"
  end
  
  desc "Clear Firebase and upload text files"
  task clear_and_upload_text: :environment do
    puts "🗑️  Clearing existing Firebase data..."
    firebase_service = FirebaseService.new
    firebase_service.clear_all_data
    puts "✅ Firebase cleared"
    
    puts "\n🔄 Starting fresh upload..."
    Rake::Task['firebase:upload_text_files'].invoke
  end
end