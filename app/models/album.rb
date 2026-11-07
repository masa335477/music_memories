class Album < ApplicationRecord
  validates :spotify_id, presence: true, uniqueness: true
  validates :name, presence: true
end
