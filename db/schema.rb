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

ActiveRecord::Schema[8.1].define(version: 2026_11_09_142101) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "albums", force: :cascade do |t|
    t.string "spotify_id", null: false
    t.string "name", null: false
    t.string "artist_name"
    t.string "release_date"
    t.string "image_url"
    t.string "spotify_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spotify_id"], name: "index_albums_on_spotify_id", unique: true
  end

  create_table "memories", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "body"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_memories_on_user_id"
  end

  create_table "memory_albums", force: :cascade do |t|
    t.bigint "memory_id", null: false
    t.bigint "album_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["album_id"], name: "index_memory_albums_on_album_id"
    t.index ["memory_id", "album_id"], name: "index_memory_albums_on_memory_id_and_album_id", unique: true
    t.index ["memory_id"], name: "index_memory_albums_on_memory_id"
  end

  create_table "memory_songs", force: :cascade do |t|
    t.bigint "memory_id", null: false
    t.bigint "song_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["memory_id", "song_id"], name: "index_memory_songs_on_memory_id_and_song_id", unique: true
    t.index ["memory_id"], name: "index_memory_songs_on_memory_id"
    t.index ["song_id"], name: "index_memory_songs_on_song_id"
  end

  create_table "songs", force: :cascade do |t|
    t.string "spotify_id", null: false
    t.string "name", null: false
    t.string "artist_name"
    t.string "album_name"
    t.string "image_url"
    t.string "spotify_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spotify_id"], name: "index_songs_on_spotify_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "memories", "users"
  add_foreign_key "memory_albums", "albums"
  add_foreign_key "memory_albums", "memories"
  add_foreign_key "memory_songs", "memories"
  add_foreign_key "memory_songs", "songs"
end
