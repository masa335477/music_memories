class CreateAlbums < ActiveRecord::Migration[8.1]
  def change
    create_table :albums do |t|
      t.string :spotify_id, null: false
      t.string :name, null: false
      t.string :artist_name
      t.string :release_date
      t.string :image_url
      t.string :spotify_url

      t.timestamps
    end

    add_index :albums, :spotify_id, unique: true
  end
end
