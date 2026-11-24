class Song < ApplicationRecord
  has_many :memory_songs, dependent: :destroy
  has_many :memories, through: :memory_songs

  validates :spotify_id, presence: true, uniqueness: true
  validates :name, presence: true
end
