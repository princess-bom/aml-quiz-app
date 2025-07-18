class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions do |t|
      t.integer :subject_id, null: false
      t.string :subject_name, null: false
      t.string :source_type, null: false
      t.string :difficulty, null: false
      t.integer :points, default: 10
      t.string :question_type, null: false
      t.text :question_text, null: false
      t.string :option_1, null: false
      t.string :option_2, null: false
      t.string :option_3, null: false
      t.string :option_4, null: false
      t.string :option_5
      t.string :correct_answer, null: false
      t.date :created_date

      t.timestamps
    end
    
    add_index :questions, [:subject_id, :difficulty]
    add_index :questions, :question_type
    add_index :questions, :source_type
  end
end
