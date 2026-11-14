
require "test_helper"

class MemoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Memory.destroy_all
  end

  test "未ログインでも投稿一覧を閲覧できる" do
    memory = create(
      :memory,
      title: "思い出のアルバム",
      body: "曲順も含めて大好きな作品です。"
    )

    get memories_path

    assert_response :success
    assert_select ".memories-page-title", text: "投稿一覧"

    assert_select "article.memory-card" do
      assert_select "h2 a[href=?]", memory_path(memory), text: memory.title
      assert_select ".memory-meta span", text: "投稿者：#{memory.user.name}"
      assert_select ".memory-body p", text: memory.body
    end
  end

  test "投稿が新しい順に表示される" do
    create(
      :memory,
      title: "古い投稿",
      created_at: 2.days.ago
    )

    create(
      :memory,
      title: "新しい投稿",
      created_at: 1.day.ago
    )

    get memories_path

    assert_response :success

    titles = css_select("article.memory-card h2").map(&:text)
    assert_equal [ "新しい投稿", "古い投稿" ], titles
  end

  test "投稿がない場合はメッセージを表示する" do
    get memories_path

    assert_response :success
    assert_select "p", text: "まだ投稿がありません。"
    assert_select "article.memory-card", count: 0
  end

  test "投稿に紐付いた楽曲とアルバムの情報を表示する" do
    song = create(
      :song,
      spotify_id: SecureRandom.alphanumeric(22),
      name: "テスト楽曲",
      artist_name: "楽曲アーティスト",
      album_name: "収録アルバム"
    )

    album = create(
      :album,
      spotify_id: SecureRandom.alphanumeric(22),
      name: "テストアルバム",
      artist_name: "アルバムアーティスト",
      release_date: "2026-11-09"
    )

    song_memory = create(
      :memory,
      title: "楽曲についての投稿",
      songs: [ song ]
    )

    album_memory = create(
      :memory,
      title: "アルバムについての投稿",
      songs: [],
      albums: [ album ]
    )

    get memories_path

    assert_response :success

    assert_select "article.memory-card",
                  text: /#{Regexp.escape(song_memory.title)}/ do
      assert_select ".memory-song" do
        assert_select "p", text: "楽曲名：テスト楽曲"
        assert_select "p", text: "アーティスト：楽曲アーティスト"
        assert_select "p", text: "収録アルバム：収録アルバム"
      end

      assert_select ".memory-album", count: 0
    end

    assert_select "article.memory-card",
                  text: /#{Regexp.escape(album_memory.title)}/ do
      assert_select ".memory-album" do
        assert_select "p", text: "アルバム名：テストアルバム"
        assert_select "p", text: "アーティスト：アルバムアーティスト"
        assert_select "p", text: "発売日：2026-11-09"
      end

      assert_select ".memory-song", count: 0
    end
  end

  test "未ログインでも投稿詳細を閲覧できる" do
    memory = create(
      :memory,
      title: "思い出のアルバム",
      body: "曲順も含めて大好きな作品です。"
    )

    get memory_path(memory)

    assert_response :success
    assert_select ".memories-page-title", text: "投稿詳細"

    assert_select "article.memory-card" do
      assert_select "h2", text: memory.title
      assert_select ".memory-meta",
                    text: /#{Regexp.escape(memory.user.name)}/
      assert_select ".memory-body p", text: memory.body
    end
  end

  test "投稿詳細に紐付いた楽曲のジャケット画像を表示する" do
    song = create(
      :song,
      spotify_id: SecureRandom.alphanumeric(22),
      name: "詳細テスト楽曲",
      image_url: "https://example.com/song.jpg"
    )

    memory = create(:memory, songs: [ song ])

    get memory_path(memory)

    assert_response :success

    assert_select ".memory-song" do
      assert_select "p", text: "楽曲名：詳細テスト楽曲"
      assert_select "img.memory-music-image[src=?]", song.image_url
    end

    assert_select ".memory-album", count: 0
  end

  test "投稿詳細に紐付いたアルバムのジャケット画像を表示する" do
    album = create(
      :album,
      spotify_id: SecureRandom.alphanumeric(22),
      name: "詳細テストアルバム",
      image_url: "https://example.com/album.jpg"
    )

    memory = create(:memory, songs: [], albums: [ album ])

    get memory_path(memory)

    assert_response :success

    assert_select ".memory-album" do
      assert_select "p", text: "アルバム名：詳細テストアルバム"
      assert_select "img.memory-music-image[src=?]", album.image_url
    end

    assert_select ".memory-song", count: 0
  end

  test "存在しない投稿IDではRecordNotFoundが発生する" do
    get memory_path(id: 999_999_999)

    assert_response :not_found
  end

    test "未ログインでも投稿フォームとログイン案内を閲覧できる" do
    get new_memory_path

    assert_response :success

    assert_select ".login-notice" do
      assert_select "p", text: "投稿するにはログインしてください。"
      assert_select "a[href=?]", login_path, text: "ログインする"
    end

    assert_select "form[action=?]", memories_path, count: 0
  end

  test "未ログインでは投稿を作成できない" do
    song = create(:song)

    assert_no_difference "Memory.count" do
      post memories_path, params: {
        memory: {
          title: "未ログインの投稿",
          body: "この投稿は保存されません。",
          spotify_track_id: song.spotify_id
        }
      }
    end

    assert_redirected_to login_path
    assert_equal "投稿するにはログインしてください。", flash[:alert]
  end

  test "ログイン中のユーザーが楽曲付きの投稿を作成できる" do
    user = login_for_memory_test
    song = create(:song)

    assert_difference [ "Memory.count", "MemorySong.count" ], 1 do
      post memories_path, params: {
        memory: {
          title: "思い出の楽曲",
          body: "通学中によく聴いていた曲です。",
          spotify_track_id: song.spotify_id
        }
      }
    end

    memory = Memory.order(:id).last

    assert_redirected_to memory_path(memory)
    assert_equal user, memory.user
    assert_equal "思い出の楽曲", memory.title
    assert_equal "通学中によく聴いていた曲です。", memory.body
    assert_equal [ song ], memory.songs.to_a
    assert_empty memory.albums
    assert_equal "投稿を作成しました。", flash[:notice]
  end

  test "ログイン中のユーザーがアルバム付きの投稿を作成できる" do
    user = login_for_memory_test
    album = create(:album)

    assert_difference [ "Memory.count", "MemoryAlbum.count" ], 1 do
      post memories_path, params: {
        memory: {
          title: "思い出のアルバム",
          body: "最初から最後まで通して聴きたい作品です。",
          spotify_album_id: album.spotify_id
        }
      }
    end

    memory = Memory.order(:id).last

    assert_redirected_to memory_path(memory)
    assert_equal user, memory.user
    assert_equal [ album ], memory.albums.to_a
    assert_empty memory.songs
  end

  test "タイトルが空の場合は保存せず入力内容と楽曲を保持する" do
    login_for_memory_test
    song = create(:song)

    assert_no_difference [ "Memory.count", "MemorySong.count" ] do
      post memories_path, params: {
        memory: {
          title: "",
          body: "入力済みの本文です。",
          spotify_track_id: song.spotify_id
        }
      }
    end

    assert_response :unprocessable_entity

    assert_select "[role='alert'] li",
                  text: "タイトルを入力してください"

    assert_select "textarea[name='memory[body]']",
                  text: "入力済みの本文です。"

    assert_select "input[name='memory[spotify_track_id]'][value=?]",
                  song.spotify_id

    assert_select ".memory-compose-music h3", text: song.name
  end

  test "本文が空の場合は保存せずタイトルとアルバムを保持する" do
    login_for_memory_test
    album = create(:album)

    assert_no_difference [ "Memory.count", "MemoryAlbum.count" ] do
      post memories_path, params: {
        memory: {
          title: "入力済みのタイトル",
          body: "",
          spotify_album_id: album.spotify_id
        }
      }
    end

    assert_response :unprocessable_entity

    assert_select "[role='alert'] li",
                  text: "本文を入力してください"

    assert_select "input[name='memory[title]'][value=?]",
                  "入力済みのタイトル"

    assert_select "input[name='memory[spotify_album_id]'][value=?]",
                  album.spotify_id

    assert_select ".memory-compose-music h3", text: album.name
  end

  test "音楽が未選択の場合は投稿を作成できない" do
    login_for_memory_test

    assert_no_difference "Memory.count" do
      post memories_path, params: {
        memory: {
          title: "音楽未選択の投稿",
          body: "本文は入力しています。"
        }
      }
    end

    assert_response :unprocessable_entity

    assert_select "[role='alert'] li",
                  text: "楽曲またはアルバムを1件選択してください"
  end

  private

  def login_for_memory_test
    user = User.create!(
      name: "投稿テストユーザー",
      email: "memory-#{SecureRandom.uuid}@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    post login_path, params: {
      session: {
        email: user.email,
        password: "password123"
      }
    }

    assert_redirected_to root_path

    user
  end
end
