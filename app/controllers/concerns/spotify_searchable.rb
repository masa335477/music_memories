
module SpotifySearchable
  extend ActiveSupport::Concern

  PER_PAGE = 10
  MAX_PAGES = 100

  private

  def search_spotify(type:)
    set_search_params
    @tracks = [] if type == :track
    @albums = [] if type == :album

    return if search_params_blank?

    offset = (@page - 1) * PER_PAGE

    client = Spotify::Client.new

    result = case type
    when :track
      client.search_tracks(
        @query,
        limit: PER_PAGE,
        offset: offset,
        artist: @artist,
        album: @album,
        year: @year
      )
    when :album
      client.search_albums(
        @query,
        limit: PER_PAGE,
        offset: offset,
        artist: @artist,
        album: @album,
        year: @year
      )
    else
      raise ArgumentError, "未対応の検索タイプ: #{type}"
    end

    if type == :track
      @tracks = result.fetch("items")
    else
      @albums = result.fetch("items")
    end

    total = result.fetch("total")
    @total_pages = [ (total.to_f / PER_PAGE).ceil, MAX_PAGES ].min
  rescue StandardError => e
    Rails.logger.error("Spotify#{type}検索エラー: #{e.message}")

    target = type == :track ? "楽曲" : "アルバム"
    flash.now[:alert] = "#{target}の検索に失敗しました。時間をおいて再度お試しください。"
  end

  def set_search_params
    @query = params[:q].to_s.strip
    @artist = params[:artist].to_s.strip
    @album = params[:album].to_s.strip
    @year = params[:year].to_s.strip

    @page = [ params[:page].to_i, 1 ].max
    @total_pages = 0
  end

  def search_params_blank?
    [ @query, @artist, @album, @year ].all?(&:blank?)
  end
end
