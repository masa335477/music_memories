class MemoryAlbum < ApplicationRecord
  belongs_to :memory
  belongs_to :album

  validates :album_id, uniqueness: { scope: :memory_id }
end
