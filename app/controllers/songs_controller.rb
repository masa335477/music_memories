class SongsController < ApplicationController
  include SpotifySearchable

  def index
    search_spotify(type: :track)
  end

  def suggestions
    spotify_suggestions(type: :track)
  end
end
