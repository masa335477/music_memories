class CreateLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :memory, null: false, foreign_key: true

      t.timestamps
    end

    add_index :likes, [ :user_id, :memory_id ], unique: true
  end
end
