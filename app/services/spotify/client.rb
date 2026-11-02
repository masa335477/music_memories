require "net/http"
require "json"

module Spotify
  class Client
    TOKEN_URL = URI("https://accounts.spotify.com/api/token")

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
  end
end
