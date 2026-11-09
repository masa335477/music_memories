require "test_helper"

class MemoriesControllerTest < ActionDispatch::IntegrationTest
  test "未ログインでも投稿一覧を閲覧できる" do
    memory = memories(:one)
    memory.update!(
      title: "思い出のアルバム",
      body: "曲順も含めて大好きな作品です。"
    )

    get memories_path

    assert_response :success
    assert_select "h1", text: "投稿一覧"

    assert_select "article.memory-card" do
      assert_select "h2 a[href=?]", memory_path(memory), text: memory.title
      assert_select "p", text: "投稿者：#{memory.user.name}"
      assert_select ".memory-body p", text: memory.body
    end
  end

  test "投稿が新しい順に表示される" do
    memories(:one).update!(
      title: "古い投稿",
      created_at: 2.days.ago
    )
    memories(:two).update!(
      title: "新しい投稿",
      created_at: 1.day.ago
    )

    get memories_path

    assert_response :success

    titles = css_select("article.memory-card h2").map(&:text)
    assert_equal [ "新しい投稿", "古い投稿" ], titles
  end

  test "投稿がない場合はメッセージを表示する" do
    Memory.destroy_all

    get memories_path

    assert_response :success
    assert_select "p", text: "まだ投稿がありません。"
    assert_select "article.memory-card", count: 0
  end

  test "投稿に紐付いた楽曲とアルバムの情報を表示する" do
    memory = memories(:one)

    song = Song.create!(
      spotify_id: "test_memory_song",
      name: "テスト楽曲",
      artist_name: "楽曲アーティスト",
      album_name: "収録アルバム"
    )

    album = Album.create!(
      spotify_id: "test_memory_album",
      name: "テストアルバム",
      artist_name: "アルバムアーティスト",
      release_date: "2026-11-09"
    )

    memory.songs << song
    memory.albums << album

    get memories_path

    assert_response :success

    assert_select "article.memory-card",
                text: /#{Regexp.escape(memory.title)}/ do
      assert_select ".memory-song" do
        assert_select "p", text: "楽曲名：テスト楽曲"
        assert_select "p", text: "アーティスト：楽曲アーティスト"
        assert_select "p", text: "収録アルバム：収録アルバム"
      end

      assert_select ".memory-album" do
        assert_select "p", text: "アルバム名：テストアルバム"
        assert_select "p", text: "アーティスト：アルバムアーティスト"
        assert_select "p", text: "発売日：2026-11-09"
      end
    end
  end
end
