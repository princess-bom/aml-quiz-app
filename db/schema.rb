# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_18_151026) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "explanations", force: :cascade do |t|
    t.integer "question_id", null: false
    t.text "correct_reason", null: false
    t.text "wrong_reason_1"
    t.text "wrong_reason_2"
    t.text "wrong_reason_3"
    t.text "wrong_reason_4"
    t.text "key_point"
    t.text "reference"
    t.text "learning_objective"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_explanations_on_question_id", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.integer "subject_id", null: false
    t.string "subject_name", null: false
    t.string "source_type", null: false
    t.string "difficulty", null: false
    t.integer "points", default: 10
    t.string "question_type", null: false
    t.text "question_text", null: false
    t.string "option_1", null: false
    t.string "option_2", null: false
    t.string "option_3", null: false
    t.string "option_4", null: false
    t.string "option_5"
    t.string "correct_answer", null: false
    t.date "created_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_type"], name: "index_questions_on_question_type"
    t.index ["source_type"], name: "index_questions_on_source_type"
    t.index ["subject_id", "difficulty"], name: "index_questions_on_subject_id_and_difficulty"
  end

  create_table "quiz_sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "subject_id", null: false
    t.string "difficulty", null: false
    t.integer "total_questions", default: 20
    t.integer "current_question", default: 1
    t.decimal "score", precision: 5, scale: 2, default: "0.0"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "status", default: "in_progress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id", "difficulty"], name: "index_quiz_sessions_on_subject_id_and_difficulty"
    t.index ["user_id", "status"], name: "index_quiz_sessions_on_user_id_and_status"
  end

  create_table "user_answers", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "question_id", null: false
    t.integer "quiz_session_id", null: false
    t.string "selected_answer", null: false
    t.boolean "is_correct", null: false
    t.datetime "answered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_correct", "user_id"], name: "index_user_answers_on_is_correct_and_user_id"
    t.index ["quiz_session_id"], name: "index_user_answers_on_quiz_session_id"
    t.index ["user_id", "question_id"], name: "index_user_answers_on_user_id_and_question_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "firebase_uid", null: false
    t.integer "total_sessions", default: 0
    t.decimal "average_score", precision: 5, scale: 2, default: "0.0"
    t.integer "study_streak", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["firebase_uid"], name: "index_users_on_firebase_uid", unique: true
  end

  create_table "wrong_answers", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "question_id", null: false
    t.integer "quiz_session_id", null: false
    t.string "selected_answer", null: false
    t.boolean "reviewed", default: false
    t.boolean "bookmarked", default: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_wrong_answers_on_question_id"
    t.index ["user_id", "bookmarked"], name: "index_wrong_answers_on_user_id_and_bookmarked"
    t.index ["user_id", "reviewed"], name: "index_wrong_answers_on_user_id_and_reviewed"
  end
end
