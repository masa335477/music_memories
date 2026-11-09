class CreateMemorySongs < ActiveRecord::Migration[8.1]
  def change
    create_table :memory_songs do |t|
      t.references :memory, null: false, foreign_key: true
      t.references :song, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end

    add_index :memory_songs, [ :memory_id, :song_id ], unique: true
  end
end
