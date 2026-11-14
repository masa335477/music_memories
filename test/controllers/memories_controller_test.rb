
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

  test "投稿者本人がタイトルと本文を更新できる" do
    user = login_for_memory_test
    song = create(:song)
    memory = create(
      :memory,
      user: user,
      songs: [ song ],
      title: "編集前のタイトル",
      body: "編集前の本文"
    )

    patch memory_path(memory), params: {
      memory: {
        title: "編集後のタイトル",
        body: "編集後の本文",
        spotify_track_id: song.spotify_id
      }
    }

    assert_redirected_to memory_path(memory)

    memory.reload

    assert_equal "編集後のタイトル", memory.title
    assert_equal "編集後の本文", memory.body
    assert_equal [ song ], memory.songs.to_a
    assert_equal "投稿を更新しました。", flash[:notice]
  end

  test "投稿に紐付く楽曲を別の楽曲へ変更できる" do
    user = login_for_memory_test

    old_song = create(:song)
    new_song = create(:song)

    memory = create(
      :memory,
      user: user,
      songs: [ old_song ]
    )

    patch memory_path(memory), params: {
      memory: {
        title: memory.title,
        body: memory.body,
        spotify_track_id: new_song.spotify_id
      }
    }

    assert_redirected_to memory_path(memory)

    memory.reload

    assert_equal [ new_song ], memory.songs.to_a
    assert_empty memory.albums
    assert_equal "投稿を更新しました。", flash[:notice]

    assert_equal 0, MemorySong.where(
      memory_id: memory.id,
      song_id: old_song.id
    ).count
  end


  test "投稿に紐付く楽曲をアルバムへ変更できる" do
    user = login_for_memory_test
    song = create(:song)
    album = create(:album)

    memory = create(
      :memory,
      user: user,
      songs: [ song ]
    )

    patch memory_path(memory), params: {
      memory: {
        title: memory.title,
        body: memory.body,
        spotify_album_id: album.spotify_id
      }
    }

    assert_redirected_to memory_path(memory)

    memory.reload

    assert_empty memory.songs
    assert_equal [ album ], memory.albums.to_a
    assert_equal 0, MemorySong.where(memory_id: memory.id).count
    assert_equal 1, MemoryAlbum.where(memory_id: memory.id).count
    assert_equal "投稿を更新しました。", flash[:notice]
  end


  test "更新に失敗した場合は投稿内容と音楽情報が維持される" do
    user = login_for_memory_test
    old_song = create(:song)
    new_song = create(:song)

    memory = create(
      :memory,
      user: user,
      songs: [ old_song ],
      title: "編集前のタイトル",
      body: "編集前の本文"
    )

    patch memory_path(memory), params: {
      memory: {
        title: "",
        body: "編集後の本文",
        spotify_track_id: new_song.spotify_id
      }
    }

    assert_response :unprocessable_entity

    assert_select "[role='alert'] li",
                  text: "タイトルを入力してください"

    memory.reload

    assert_equal "編集前のタイトル", memory.title
    assert_equal "編集前の本文", memory.body
    assert_equal [ old_song ], memory.songs.reload.to_a
    assert_empty memory.albums.reload
    assert_equal 0, MemorySong.where(
      memory_id: memory.id,
      song_id: new_song.id
    ).count
  end


  test "他人の投稿を更新できない" do
    login_for_memory_test

    other_user = create(:user)
    song = create(:song)

    memory = create(
      :memory,
      user: other_user,
      songs: [ song ],
      title: "他人の投稿",
      body: "変更前の本文"
    )

    patch memory_path(memory), params: {
      memory: {
        title: "不正に変更したタイトル",
        body: "不正に変更した本文",
        spotify_track_id: song.spotify_id
      }
    }

    assert_redirected_to memories_path
    assert_equal "指定された投稿は存在しないか、操作する権限がありません。", flash[:alert]

    memory.reload

    assert_equal "他人の投稿", memory.title
    assert_equal "変更前の本文", memory.body
    assert_equal [ song ], memory.songs.to_a
  end

  test "他人の投稿の編集画面にアクセスできない" do
    login_for_memory_test

    other_user = create(:user)
    memory = create(:memory, user: other_user)

    get edit_memory_path(memory)

    assert_redirected_to memories_path
    assert_equal "指定された投稿は存在しないか、操作する権限がありません。", flash[:alert]
  end

  test "未ログインでは投稿の編集画面にアクセスできない" do
    memory = create(:memory)

    get edit_memory_path(memory)

    assert_redirected_to login_path
    assert_equal "投稿するにはログインしてください。", flash[:alert]
  end

  test "未ログインでは投稿を更新できない" do
    memory = create(
      :memory,
      title: "編集前のタイトル",
      body: "編集前の本文"
    )

    patch memory_path(memory), params: {
      memory: {
        title: "不正な更新",
        body: "不正に変更された本文"
      }
    }

    assert_redirected_to login_path

    memory.reload

    assert_equal "編集前のタイトル", memory.title
    assert_equal "編集前の本文", memory.body
  end


  test "投稿者本人が投稿を削除できる" do
    user = login_for_memory_test
    song = create(:song)

    memory = create(
      :memory,
      user: user,
      songs: [ song ]
    )

    assert_difference "Memory.count", -1 do
      assert_difference "MemorySong.count", -1 do
        delete memory_path(memory)
      end
    end

    assert_redirected_to memories_path
    assert_equal "投稿を削除しました。", flash[:notice]

    assert_nil Memory.find_by(id: memory.id)
    assert Song.exists?(song.id)
  end

  test "他人の投稿を削除できない" do
    login_for_memory_test

    other_user = create(:user)
    song = create(:song)

    memory = create(
      :memory,
      user: other_user,
      songs: [ song ]
    )

    assert_no_difference [ "Memory.count", "MemorySong.count" ] do
      delete memory_path(memory)
    end

    assert_redirected_to memories_path
    assert_equal "指定された投稿は存在しないか、操作する権限がありません。", flash[:alert]

    assert Memory.exists?(memory.id)
    assert_equal [ song ], memory.reload.songs.to_a
  end


  test "未ログインでは投稿を削除できない" do
    song = create(:song)
    memory = create(:memory, songs: [ song ])

    assert_no_difference [ "Memory.count", "MemorySong.count" ] do
      delete memory_path(memory)
    end

    assert_redirected_to login_path
    assert_equal "投稿するにはログインしてください。", flash[:alert]

    assert Memory.exists?(memory.id)
    assert_equal [ song ], memory.reload.songs.to_a
  end


  test "アルバム付き投稿を削除すると関連付けも削除される" do
    user = login_for_memory_test
    album = create(:album)

    memory = create(
      :memory,
      user: user,
      songs: [],
      albums: [ album ]
    )

    assert_difference "Memory.count", -1 do
      assert_difference "MemoryAlbum.count", -1 do
        delete memory_path(memory)
      end
    end

    assert_redirected_to memories_path
    assert_equal "投稿を削除しました。", flash[:notice]

    assert_not Memory.exists?(memory.id)
    assert Album.exists?(album.id)
  end


  test "編集した内容が投稿一覧と詳細画面に反映される" do
    user = login_for_memory_test
    song = create(:song)

    memory = create(
      :memory,
      user: user,
      songs: [ song ],
      title: "編集前のタイトル",
      body: "編集前の本文"
    )

    patch memory_path(memory), params: {
      memory: {
        title: "編集後のタイトル",
        body: "編集後の本文",
        spotify_track_id: song.spotify_id
      }
    }

    assert_redirected_to memory_path(memory)

    get memory_path(memory)

    assert_response :success
    assert_select "article.memory-card" do
      assert_select "h2", text: "編集後のタイトル"
      assert_select ".memory-body p", text: "編集後の本文"
    end

    get memories_path

    assert_response :success
    assert_select "article.memory-card" do
      assert_select "h2", text: /編集後のタイトル/
      assert_select ".memory-body p", text: "編集後の本文"
    end

    assert_select "h2", text: "編集前のタイトル", count: 0
  end


  test "削除した投稿が一覧と詳細画面に表示されない" do
    user = login_for_memory_test
    song = create(:song)

    memory = create(
      :memory,
      user: user,
      songs: [ song ],
      title: "削除対象の投稿"
    )

    delete memory_path(memory)

    assert_redirected_to memories_path

    get memories_path

    assert_response :success
    assert_select "article.memory-card", text: /削除対象の投稿/, count: 0

    get memory_path(memory)

    assert_response :not_found
  end


  test "更新失敗時に入力内容と選択した楽曲を編集画面に保持する" do
    user = login_for_memory_test
    old_song = create(:song)
    new_song = create(:song)

    memory = create(
      :memory,
      user: user,
      songs: [ old_song ],
      title: "編集前のタイトル",
      body: "編集前の本文"
    )

    patch memory_path(memory), params: {
      memory: {
        title: "",
        body: "入力途中の本文",
        spotify_track_id: new_song.spotify_id
      }
    }

    assert_response :unprocessable_entity

    assert_select "[role='alert'] li",
                  text: "タイトルを入力してください"

    assert_select "textarea[name='memory[body]']",
                  text: "入力途中の本文"

    assert_select "input[name='memory[spotify_track_id]'][value=?]",
                  new_song.spotify_id

    assert_select ".memory-compose-music h3", text: new_song.name

    memory.reload
    assert_equal "編集前のタイトル", memory.title
    assert_equal [ old_song ], memory.songs.to_a
  end


  test "投稿に紐付くアルバムを楽曲へ変更できる" do
    user = login_for_memory_test
    album = create(:album)
    song = create(:song)

    memory = create(
      :memory,
      user: user,
      songs: [],
      albums: [ album ]
    )

    patch memory_path(memory), params: {
      memory: {
        title: memory.title,
        body: memory.body,
        spotify_track_id: song.spotify_id
      }
    }

    assert_redirected_to memory_path(memory)

    memory.reload

    assert_equal [ song ], memory.songs.to_a
    assert_empty memory.albums
    assert_equal 1, MemorySong.where(memory_id: memory.id).count
    assert_equal 0, MemoryAlbum.where(memory_id: memory.id).count
    assert_equal "投稿を更新しました。", flash[:notice]
  end


  test "投稿に紐付くアルバムを別のアルバムへ変更できる" do
    user = login_for_memory_test
    old_album = create(:album)
    new_album = create(:album)

    memory = create(
      :memory,
      user: user,
      songs: [],
      albums: [ old_album ]
    )

    patch memory_path(memory), params: {
      memory: {
        title: memory.title,
        body: memory.body,
        spotify_album_id: new_album.spotify_id
      }
    }

    assert_redirected_to memory_path(memory)

    memory.reload

    assert_equal [ new_album ], memory.albums.to_a
    assert_empty memory.songs

    assert_equal 0, MemoryAlbum.where(
      memory_id: memory.id,
      album_id: old_album.id
    ).count

    assert_equal 1, MemoryAlbum.where(
      memory_id: memory.id,
      album_id: new_album.id
    ).count

    assert_equal "投稿を更新しました。", flash[:notice]
  end


  test "Spotify APIの取得に失敗した場合は投稿を更新しない" do
    user = login_for_memory_test
    old_song = create(:song)

    memory = create(
      :memory,
      user: user,
      songs: [ old_song ],
      title: "編集前のタイトル",
      body: "編集前の本文"
    )

    new_spotify_id = "spotify_api_failure_test"


    spotify_client = Spotify::Client.singleton_class
    original_new = Spotify::Client.method(:new)

    spotify_client.define_method(:new) do |*_args|
      raise Timeout::Error
    end

    begin
      patch memory_path(memory), params: {
        memory: {
          title: "編集後のタイトル",
          body: "編集後の本文",
          spotify_track_id: new_spotify_id
        }
      }
    ensure
      spotify_client.define_method(:new, original_new)
    end


    assert_response :unprocessable_entity

    assert_select "[role='alert'] li",
                  text: "音楽情報を取得できませんでした。時間をおいて再度お試しください。"

    memory.reload

    assert_equal "編集前のタイトル", memory.title
    assert_equal "編集前の本文", memory.body
    assert_equal [ old_song ], memory.songs.to_a

    assert_not Song.exists?(spotify_id: new_spotify_id)
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
