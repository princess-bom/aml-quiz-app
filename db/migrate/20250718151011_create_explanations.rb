class CreateExplanations < ActiveRecord::Migration[8.0]
  def change
    create_table :explanations do |t|
      t.integer :question_id, null: false
      t.text :correct_reason, null: false
      t.text :wrong_reason_1
      t.text :wrong_reason_2
      t.text :wrong_reason_3
      t.text :wrong_reason_4
      t.text :key_point
      t.text :reference
      t.text :learning_objective

      t.timestamps
    end
    
    add_index :explanations, :question_id, unique: true
  end
end
