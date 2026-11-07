require "net/http"
require "json"

module Spotify
  class Client
    TOKEN_URL = URI("https://accounts.spotify.com/api/token")
    SEARCH_URL = URI("https://api.spotify.com/v1/search")

    def access_token
      credentials = Rails.application.credentials.spotify

      request = Net::HTTP::Post.new(TOKEN_URL)
      request.basic_auth(
        credentials[:client_id],
        credentials[:client_secret]
      )
      request.set_form_data(grant_type: "client_credentials")

      response = Net::HTTP.start(
        TOKEN_URL.hostname,
        TOKEN_URL.port,
        use_ssl: true,
        open_timeout: 5,
        read_timeout: 10
      ) do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        error = JSON.parse(response.body)
        raise "Spotify認証に失敗しました（HTTP #{response.code} / #{error['error']})"
      end

      JSON.parse(response.body).fetch("access_token")
    end


    def search_tracks(query, limit: 10, offset: 0, artist: nil, album: nil, year: nil)
      search(
        query,
        type: "track",
        limit: limit,
        offset: offset,
        artist: artist,
        album: album,
        year: year
      )
    end

    def search_albums(query, limit: 10, offset: 0, artist: nil, album: nil, year: nil)
      search(
        query,
        type: "album",
        limit: limit,
        offset: offset,
        artist: artist,
        album: album,
        year: year
      )
    end

    private

    def search(query, type:, limit:, offset:, artist:, album:, year:)
      search_terms = []

      search_terms << query if query.present?
      search_terms << "artist:#{artist}" if artist.present?
      search_terms << "album:#{album}" if album.present?
      search_terms << "year:#{year}" if year.present?

      search_query = search_terms.join(" ")

      uri = SEARCH_URL.dup
      uri.query = URI.encode_www_form(
        q: search_query,
        type: type,
        limit: limit,
        offset: offset
      )

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{access_token}"

      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: true,
        open_timeout: 5,
        read_timeout: 10
      ) do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise "Spotify検索に失敗しました（HTTP #{response.code}）"
      end

      JSON.parse(response.body).fetch("#{type}s")
    end
  end
end
