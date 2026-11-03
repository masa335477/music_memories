class SongsController < ApplicationController
  PER_PAGE = 10

  def index
    @query = params[:q].to_s.strip
    @artist = params[:artist].to_s.strip
    @album = params[:album].to_s.strip
    @year = params[:year].to_s.strip

    @tracks = []
    @page = [ params[:page].to_i, 1 ].max
    @total_pages = 0

    return if [ @query, @artist, @album, @year ].all?(&:blank?)

    offset = (@page - 1) * PER_PAGE

    result = Spotify::Client.new.search_tracks(
      @query,
      limit: PER_PAGE,
      offset: offset,
      artist: @artist,
      album: @album,
      year: @year
    )

    @tracks = result.fetch("items")
    total = result.fetch("total")

    @total_pages = [ (total.to_f / PER_PAGE).ceil, 100 ].min
  rescue StandardError => e
    Rails.logger.error("Spotify楽曲検索エラー: #{e.message}")
    flash.now[:alert] = "楽曲の検索に失敗しました。時間をおいて再度お試しください。"
  end
end
