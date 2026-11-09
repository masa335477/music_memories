class Album < ApplicationRecord
  has_many :memory_albums, dependent: :destroy
  has_many :memories, through: :memory_albums

  validates :spotify_id, presence: true, uniqueness: true
  validates :name, presence: true
end
