require "test_helper"

module Spotify
  class ClientTest < ActiveSupport::TestCase
    setup do
      @original_credentials_method = Rails.application.credentials.method(:spotify)

      Rails.application.credentials.define_singleton_method(:spotify) do
        {
          client_id: "test_client_id",
          client_secret: "test_client_secret"
        }
      end
    end

    teardown do
      Rails.application.credentials.define_singleton_method(
        :spotify,
        @original_credentials_method
      )
    end

    test "アクセストークンを取得できる" do
      response = Object.new

      response.define_singleton_method(:is_a?) do |klass|
        klass == Net::HTTPSuccess || super(klass)
      end

      response.define_singleton_method(:body) do
        '{"access_token":"test_access_token"}'
      end

      fake_http = Object.new

      fake_http.define_singleton_method(:request) do |_request|
        response
      end

      net_http = Net::HTTP.singleton_class
      original_start = Net::HTTP.method(:start)

      net_http.define_method(:start) do |*_args, **_kwargs, &block|
        block.call(fake_http)
      end

      begin
        token = Spotify::Client.new.access_token

        assert_equal "test_access_token", token
      ensure
        net_http.define_method(:start, original_start)
      end
    end

    test "認証に失敗した場合はエラーを発生させる" do
      response = Object.new

      response.define_singleton_method(:is_a?) do |klass|
        super(klass)
      end

      response.define_singleton_method(:code) do
        "400"
      end

      response.define_singleton_method(:body) do
        '{"error":"invalid_client"}'
      end

      fake_http = Object.new

      fake_http.define_singleton_method(:request) do |_request|
        response
      end

      net_http = Net::HTTP.singleton_class
      original_start = Net::HTTP.method(:start)

      net_http.define_method(:start) do |*_args, **_kwargs, &block|
        block.call(fake_http)
      end

      begin
        error = assert_raises(RuntimeError) do
          Spotify::Client.new.access_token
        end

        assert_includes error.message, "Spotify認証に失敗しました"
        assert_includes error.message, "400"
        assert_includes error.message, "invalid_client"
      ensure
        net_http.define_method(:start, original_start)
      end
    end

    test "楽曲情報を取得できる" do
      spotify_id = "a" * 22

      response = Object.new
      response.define_singleton_method(:is_a?) do |klass|
        klass == Net::HTTPSuccess || super(klass)
      end

      response.define_singleton_method(:body) do
        { id: spotify_id, name: "テスト楽曲" }.to_json
      end

      fake_http = Object.new

      test_case = self

      fake_http.define_singleton_method(:request) do |request|
        test_case.assert_equal "/v1/tracks/#{spotify_id}", request.path
        response
      end

      client = Spotify::Client.new
      client.define_singleton_method(:access_token) { "test_access_token" }

      net_http = Net::HTTP.singleton_class
      original_start = Net::HTTP.method(:start)

      net_http.define_method(:start) do |*_args, **_kwargs, &block|
        block.call(fake_http)
      end

      begin
        track = client.get_track(spotify_id)

        assert_equal spotify_id, track["id"]
        assert_equal "テスト楽曲", track["name"]
      ensure
        net_http.define_method(:start, original_start)
      end
    end

    test "アルバム情報を取得できる" do
      spotify_id = "b" * 22

      response = Object.new
      response.define_singleton_method(:is_a?) do |klass|
        klass == Net::HTTPSuccess || super(klass)
      end
      response.define_singleton_method(:body) do
        { id: spotify_id, name: "テストアルバム" }.to_json
      end

      fake_http = Object.new

      test_case = self

      fake_http.define_singleton_method(:request) do |request|
        test_case.assert_equal "/v1/albums/#{spotify_id}", request.path
        response
      end

      client = Spotify::Client.new
      client.define_singleton_method(:access_token) { "test_access_token" }

      net_http = Net::HTTP.singleton_class
      original_start = Net::HTTP.method(:start)

      net_http.define_method(:start) do |*_args, **_kwargs, &block|
        block.call(fake_http)
      end

      begin
        album = client.get_album(spotify_id)

        assert_equal spotify_id, album["id"]
        assert_equal "テストアルバム", album["name"]
      ensure
        net_http.define_method(:start, original_start)
      end
    end

    test "不正なSpotify IDの場合はエラーを発生させる" do
      client = Spotify::Client.new

      error = assert_raises(ArgumentError) do
        client.get_track("invalid_id")
      end

      assert_includes error.message, "Spotify IDの形式が正しくありません"
    end

    test "Spotify APIがエラーを返した場合は例外を発生させる" do
      spotify_id = "c" * 22

      response = Object.new
      response.define_singleton_method(:is_a?) do |klass|
        super(klass)
      end
      response.define_singleton_method(:code) { "404" }

      fake_http = Object.new
      fake_http.define_singleton_method(:request) do |_request|
        response
      end

      client = Spotify::Client.new
      client.define_singleton_method(:access_token) { "test_access_token" }

      net_http = Net::HTTP.singleton_class
      original_start = Net::HTTP.method(:start)

      net_http.define_method(:start) do |*_args, **_kwargs, &block|
        block.call(fake_http)
      end

      begin
        error = assert_raises(RuntimeError) do
          client.get_track(spotify_id)
        end

        assert_includes error.message, "Spotify情報の取得に失敗しました"
        assert_includes error.message, "404"
      ensure
        net_http.define_method(:start, original_start)
      end
    end
  end
end
