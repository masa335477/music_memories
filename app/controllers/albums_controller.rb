class AlbumsController < ApplicationController
  include SpotifySearchable

  def index
    search_spotify(type: :album)
  end
end
