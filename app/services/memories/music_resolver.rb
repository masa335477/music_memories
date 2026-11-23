module Memories
  class MusicResolver
    def initialize(memory:)
      @memory = memory
    end

    def resolve(model:, spotify_id:)
      music = model.find_by(spotify_id: spotify_id)
      return music if music

      method = model == Song ? :get_track : :get_album
      item = Spotify::Client.new.public_send(method, spotify_id)
      return nil unless item

      attributes = if model == Song
        song_attributes(item)
      else
        album_attributes(item)
      end

      model.new(attributes.merge(spotify_id: spotify_id))
    rescue RuntimeError, ArgumentError, KeyError, JSON::ParserError,
           Timeout::Error, SocketError, EOFError,
           SystemCallError, OpenSSL::SSL::SSLError
      @memory.errors.add(
        :base,
        "音楽情報を取得できませんでした。時間をおいて再度お試しください。"
      )
      nil
    end

    private

    def common_attributes(item)
      {
        name: item.fetch("name"),
        artist_name: item.fetch("artists")
                         .map { |artist| artist["name"] }
                         .join(", "),
        spotify_url: item.dig("external_urls", "spotify")
      }
    end

    def song_attributes(item)
      common_attributes(item).merge(
        album_name: item.dig("album", "name"),
        image_url: item.dig("album", "images")&.first&.dig("url")
      )
    end

    def album_attributes(item)
      common_attributes(item).merge(
        release_date: item["release_date"],
        image_url: item["images"]&.first&.dig("url")
      )
    end
  end
end
