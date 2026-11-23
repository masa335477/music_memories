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

  def self.search(query)
    return all if query.blank?

    if query.start_with?("#", "＃")
      tag_name = query[1..].strip
      return none if tag_name.blank?

      return joins(:tags).where("tags.name ILIKE ?", "%#{sanitize_sql_like(tag_name)}%").distinct
    end

    left_joins(:songs, :albums, :tags).where(<<~SQL, query: "%#{sanitize_sql_like(query)}%").distinct
      memories.title ILIKE :query OR memories.body ILIKE :query
        OR songs.name ILIKE :query OR songs.artist_name ILIKE :query OR songs.album_name ILIKE :query
        OR albums.name ILIKE :query OR albums.artist_name ILIKE :query
        OR tags.name ILIKE :query
    SQL
  end

  private

  def must_have_one_music
    return if songs.size + albums.size == 1

    errors.add(:base, "楽曲またはアルバムを1件選択してください")
  end
end
