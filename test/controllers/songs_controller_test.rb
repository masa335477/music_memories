require "test_helper"

class SongsControllerTest < ActionDispatch::IntegrationTest
  test "楽曲検索画面を表示できる" do
    get songs_url

    assert_response :success
  end

  test "フリーワードで楽曲を検索できる" do
    with_fake_spotify_client do |calls|
      get songs_url, params: { q: "スピッツ" }

      assert_response :success
      assert_equal 1, calls.size
      assert_equal "スピッツ", calls.first[:query]
    end
  end

  test "詳細検索の条件をSpotifyに渡せる" do
    with_fake_spotify_client do |calls|
      get songs_url, params: {
        artist: "スピッツ",
        album: "ハチミツ",
        year: "1995"
      }

      assert_response :success
      assert_equal 1, calls.size

      assert_equal "", calls.first[:query]
      assert_equal "スピッツ", calls.first[:artist]
      assert_equal "ハチミツ", calls.first[:album]
      assert_equal "1995", calls.first[:year]
    end
  end

  test "2ページ目ではoffsetが10になる" do
    with_fake_spotify_client do |calls|
      get songs_url, params: {
        q: "スピッツ",
        page: 2
      }

      assert_response :success
      assert_equal 1, calls.size
      assert_equal 10, calls.first[:offset]
      assert_equal 10, calls.first[:limit]
    end
  end

  test "検索結果が0件の場合は案内を表示する" do
    with_fake_spotify_client do |calls|
      get songs_path, params: { q: "存在しない楽曲" }

      assert_response :success
      assert_equal 1, calls.size
      assert_select "p", text: "該当する楽曲が見つかりませんでした。"
    end
  end


  test "2文字未満の検索候補ではSpotify APIを呼び出さない" do
    get song_suggestions_url, params: { q: "サ" }

    assert_response :success
    assert_equal [], response.parsed_body["suggestions"]
  end

  test "空文字の検索候補では空配列を返す" do
    get song_suggestions_url, params: { q: "" }

    assert_response :success
    assert_equal [], response.parsed_body["suggestions"]
  end

  test "101文字以上の検索候補では空配列を返す" do
    get song_suggestions_url, params: { q: "あ" * 101 }

    assert_response :success
    assert_equal [], response.parsed_body["suggestions"]
  end


  test "楽曲検索候補のJSONを返す" do
    items = [
      {
        "id" => "spotify-track-id",
        "name" => "TSUNAMI",
        "artists" => [ { "name" => "サザンオールスターズ" } ],
        "album" => {
          "images" => [ { "url" => "https://example.com/cover.jpg" } ]
        }
      }
    ]

    with_fake_spotify_client(items: items) do |calls|
      get song_suggestions_url, params: { q: "サザン" }

      assert_response :success
      assert_equal 1, calls.size
      assert_equal "サザン", calls.first[:query]
      assert_equal 5, calls.first[:limit]

      suggestion = response.parsed_body["suggestions"].first

      assert_equal "spotify-track-id", suggestion["id"]
      assert_equal "TSUNAMI", suggestion["name"]
      assert_equal "サザンオールスターズ", suggestion["artist"]
      assert_equal "https://example.com/cover.jpg", suggestion["image_url"]
    end
  end

  test "Spotify APIエラー時は502を返す" do
    with_fake_spotify_client(raise_error: true) do
      get song_suggestions_url, params: { q: "サザン" }

      assert_response :bad_gateway
      assert_equal [], response.parsed_body["suggestions"]
      assert_equal "検索候補を取得できませんでした。",
                   response.parsed_body["error"]
    end
  end

  private

  def with_fake_spotify_client(items: [], raise_error: false)
    calls = []

    fake_client = Object.new

    fake_client.define_singleton_method(:search_tracks) do |query, **options|
      calls << { query: query, **options }

      raise "Spotify API error" if raise_error

      {
        "items" => items,
        "total" => items.size
      }
    end

    client_class = Spotify::Client.singleton_class
    original_new = Spotify::Client.method(:new)

    client_class.define_method(:new) do |*_args, **_kwargs|
      fake_client
    end

    begin
      yield calls
    ensure
      client_class.define_method(:new, original_new)
    end
  end
end
