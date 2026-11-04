
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

  private

  def with_fake_spotify_client
    calls = []

    fake_client = Object.new

    fake_client.define_singleton_method(:search_tracks) do |query, **options|
      calls << { query: query, **options }

      {
        "items" => [],
        "total" => 0
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
