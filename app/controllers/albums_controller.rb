class AlbumsController < ApplicationController
  include SpotifySearchable

  def index
    search_spotify(type: :album)
  end

  def suggestions
    spotify_suggestions(type: :album)
  end
end
