class CreateMemoryAlbums < ActiveRecord::Migration[8.1]
  def change
    create_table :memory_albums do |t|
      t.references :memory, null: false, foreign_key: true
      t.references :album, null: false, foreign_key: true

      t.timestamps
    end

    add_index :memory_albums, [ :memory_id, :album_id ], unique: true
  end
end
