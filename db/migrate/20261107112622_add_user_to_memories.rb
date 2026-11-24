class AddUserToMemories < ActiveRecord::Migration[8.1]
  def change
    add_reference :memories, :user, null: false, foreign_key: true
  end
end
