class MemorySong < ApplicationRecord
  belongs_to :memory
  belongs_to :song

  validates :song_id, uniqueness: { scope: :memory_id }
end
