class AddBodyToMemories < ActiveRecord::Migration[8.1]
  def change
    add_column :memories, :body, :text
  end
end
