class SongsController < ApplicationController
  include SpotifySearchable

  def index
    search_spotify(type: :track)
  end
end
