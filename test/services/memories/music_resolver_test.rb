require "test_helper"
require "minitest/mock"

class Memories::MusicResolverTest < ActiveSupport::TestCase
  setup do
    @memory = Memory.new
    @resolver = Memories::MusicResolver.new(memory: @memory)
  end

  test "既存の楽曲を再利用する場合はAPIを呼び出さない" do
    song = Song.create!(
      spotify_id: "existing-track",
      name: "既存楽曲",
      artist_name: "テストアーティスト"
    )

    Spotify::Client.stub(:new, -> { flunk("APIを呼び出してはいけません") }) do
      result = @resolver.resolve(
        model: Song,
        spotify_id: song.spotify_id
      )

      assert_equal song, result
    end
  end

  test "Spotify APIの情報から楽曲を構築する" do
    response = {
      "name" => "新しい楽曲",
      "artists" => [ { "name" => "アーティストA" } ],
      "album" => {
        "name" => "アルバムA",
        "images" => [ { "url" => "https://example.com/song.jpg" } ]
      },
      "external_urls" => {
        "spotify" => "https://open.spotify.com/track/new-track"
      }
    }

    client = Minitest::Mock.new
    client.expect(:get_track, response, [ "new-track" ])

    Spotify::Client.stub(:new, client) do
      result = @resolver.resolve(
        model: Song,
        spotify_id: "new-track"
      )

      assert_instance_of Song, result
      assert_not result.persisted?
      assert_equal "新しい楽曲", result.name
      assert_equal "アーティストA", result.artist_name
      assert_equal "アルバムA", result.album_name
    end

    client.verify
  end

  test "Spotify APIの情報からアルバムを構築する" do
    response = {
      "name" => "新しいアルバム",
      "artists" => [ { "name" => "アーティストB" } ],
      "release_date" => "2026-01-01",
      "images" => [ { "url" => "https://example.com/album.jpg" } ],
      "external_urls" => {
        "spotify" => "https://open.spotify.com/album/new-album"
      }
    }

    client = Minitest::Mock.new
    client.expect(:get_album, response, [ "new-album" ])

    Spotify::Client.stub(:new, client) do
      result = @resolver.resolve(
        model: Album,
        spotify_id: "new-album"
      )

      assert_instance_of Album, result
      assert_not result.persisted?
      assert_equal "新しいアルバム", result.name
      assert_equal "アーティストB", result.artist_name
      assert_equal "2026-01-01", result.release_date
    end

    client.verify
  end

  test "Spotify APIで例外が発生した場合はエラーを追加する" do
    client = Object.new

    def client.get_track(_spotify_id)
      raise RuntimeError, "API error"
    end

    Spotify::Client.stub(:new, client) do
      result = @resolver.resolve(
        model: Song,
        spotify_id: "error-track"
      )

      assert_nil result
      assert_includes(
        @memory.errors[:base],
        "音楽情報を取得できませんでした。時間をおいて再度お試しください。"
      )
    end
  end
end
