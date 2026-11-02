require "test_helper"

module Spotify
  class ClientTest < ActiveSupport::TestCase
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
  end
end
