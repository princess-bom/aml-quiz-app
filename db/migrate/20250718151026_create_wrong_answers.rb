class CreateWrongAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :wrong_answers do |t|
      t.integer :user_id, null: false
      t.integer :question_id, null: false
      t.integer :quiz_session_id, null: false
      t.string :selected_answer, null: false
      t.boolean :reviewed, default: false
      t.boolean :bookmarked, default: false
      t.text :note

      t.timestamps
    end
    
    add_index :wrong_answers, [:user_id, :reviewed]
    add_index :wrong_answers, [:user_id, :bookmarked]
    add_index :wrong_answers, :question_id
  end
end
