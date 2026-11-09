class Memory < ApplicationRecord
  belongs_to :user

  has_many :memory_songs, dependent: :destroy
  has_many :songs, through: :memory_songs

  has_many :memory_albums, dependent: :destroy
  has_many :albums, through: :memory_albums
end
