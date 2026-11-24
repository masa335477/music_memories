class Like < ApplicationRecord
  belongs_to :user
  belongs_to :memory

  validates :user_id, uniqueness: { scope: :memory_id }
end
