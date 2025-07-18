class CreateQuizSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_sessions do |t|
      t.integer :user_id, null: false
      t.integer :subject_id, null: false
      t.string :difficulty, null: false
      t.integer :total_questions, default: 20
      t.integer :current_question, default: 1
      t.decimal :score, precision: 5, scale: 2, default: 0.0
      t.datetime :start_time
      t.datetime :end_time
      t.string :status, default: 'in_progress'

      t.timestamps
    end
    
    add_index :quiz_sessions, [:user_id, :status]
    add_index :quiz_sessions, [:subject_id, :difficulty]
  end
end
