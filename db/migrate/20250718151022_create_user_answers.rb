class CreateUserAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :user_answers do |t|
      t.integer :user_id, null: false
      t.integer :question_id, null: false
      t.integer :quiz_session_id, null: false
      t.string :selected_answer, null: false
      t.boolean :is_correct, null: false
      t.datetime :answered_at

      t.timestamps
    end
    
    add_index :user_answers, [:user_id, :question_id]
    add_index :user_answers, :quiz_session_id
    add_index :user_answers, [:is_correct, :user_id]
  end
end
