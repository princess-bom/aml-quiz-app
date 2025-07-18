class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :firebase_uid, null: false
      t.integer :total_sessions, default: 0
      t.decimal :average_score, precision: 5, scale: 2, default: 0.0
      t.integer :study_streak, default: 0

      t.timestamps
    end
    
    add_index :users, :email, unique: true
    add_index :users, :firebase_uid, unique: true
  end
end
