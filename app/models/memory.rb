class Memory < ApplicationRecord
  belongs_to :user

  has_many :memory_songs, dependent: :destroy
  has_many :songs, through: :memory_songs

  has_many :memory_albums, dependent: :destroy
  has_many :albums, through: :memory_albums

  attr_accessor :spotify_track_id, :spotify_album_id

  validates :title, presence: { message: "を入力してください" }
  validates :body, presence: { message: "を入力してください" }

  validate :must_have_one_music

  private

  def must_have_one_music
    return if songs.size + albums.size == 1

    errors.add(:base, "楽曲またはアルバムを1件選択してください")
  end
end
