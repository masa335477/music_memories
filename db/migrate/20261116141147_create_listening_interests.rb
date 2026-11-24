class CreateListeningInterests < ActiveRecord::Migration[8.1]
  def change
    create_table :listening_interests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :memory, null: false, foreign_key: true

      t.timestamps
    end

    add_index :listening_interests, [ :user_id, :memory_id ], unique: true
  end
end
