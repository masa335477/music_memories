class Memory < ApplicationRecord
  belongs_to :user

  has_many :memory_songs, dependent: :destroy
  has_many :songs, through: :memory_songs

  has_many :memory_albums, dependent: :destroy
  has_many :albums, through: :memory_albums

  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :listening_interests, dependent: :destroy

  has_many :memory_tags, dependent: :destroy
  has_many :tags, through: :memory_tags

  attr_accessor :spotify_track_id, :spotify_album_id, :new_tag_name

  validates :title, presence: { message: "を入力してください" }
  validates :body, presence: { message: "を入力してください" }

  validate :must_have_one_music

  private

  def must_have_one_music
    return if songs.size + albums.size == 1

    errors.add(:base, "楽曲またはアルバムを1件選択してください")
  end
end
