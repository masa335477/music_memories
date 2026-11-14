require "test_helper"

class MemoryTest < ActiveSupport::TestCase
  test "FactoryBotでMemoryを作成できる" do
    memory = build(:memory)

    assert_equal "テスト用の思い出", memory.title
    assert memory.valid?
  end

  test "Fakerでテストデータを生成できる" do
    title = Faker::Lorem.sentence

    assert title.is_a?(String)
    assert_not title.empty?
  end

  test "Shoulda Matchersでtitleカラムを確認できる" do
    matcher = have_db_column(:title).of_type(:string)

    assert matcher.matches?(Memory.new), matcher.failure_message
  end

  test "タイトルが空の場合は無効になる" do
    memory = build(:memory, title: "")

    assert_not memory.valid?
    assert memory.errors.added?(:title, :blank)
  end

  test "本文が空の場合は無効になる" do
    memory = build(:memory, body: "")

    assert_not memory.valid?
    assert memory.errors.added?(:body, :blank)
  end

  test "音楽が未選択の場合は無効になる" do
    memory = build(:memory, songs: [], albums: [])

    assert_not memory.valid?
    assert_includes memory.errors[:base],
                    "楽曲またはアルバムを1件選択してください"
  end

  test "アルバムを1件紐づけた投稿は有効になる" do
    album = build(:album, spotify_id: SecureRandom.alphanumeric(22))
    memory = build(:memory, songs: [], albums: [ album ])

    assert memory.valid?, memory.errors.full_messages.join(", ")
  end

  test "楽曲とアルバムを両方紐づけた投稿は無効になる" do
    album = build(:album, spotify_id: SecureRandom.alphanumeric(22))
    memory = build(:memory, albums: [ album ])

    assert_not memory.valid?
    assert_includes memory.errors[:base],
                    "楽曲またはアルバムを1件選択してください"
  end

  test "楽曲を2件紐づけた投稿は無効になる" do
    songs = Array.new(2) do
      build(:song, spotify_id: SecureRandom.alphanumeric(22))
    end

    memory = build(:memory, songs: songs)

    assert_not memory.valid?
    assert_includes memory.errors[:base],
                    "楽曲またはアルバムを1件選択してください"
  end
end
