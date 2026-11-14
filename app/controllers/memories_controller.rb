class MemoriesController < ApplicationController
  before_action :require_login, only: [ :create ]

  def index
    @memories = Memory.includes(:user, :songs, :albums).order(created_at: :desc, id: :desc)
  end

  def new
    @memory = Memory.new(
      params.permit(:spotify_track_id, :spotify_album_id)
    )

    attach_music
  end

  def create
    @memory = current_user.memories.build(memory_params)

    music_loaded = attach_music

    if music_loaded && @memory.save
      redirect_to memory_path(@memory), notice: "投稿を作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @memory = Memory.includes(:user, :songs, :albums).find(params[:id])
  end

  private

  def require_login
    return if logged_in?

    redirect_to login_path, alert: "投稿するにはログインしてください。"
  end

  def memory_params
    params.require(:memory).permit(
      :title,
      :body,
      :spotify_track_id,
      :spotify_album_id
    )
  end

  def attach_music
    if @memory.spotify_track_id.present? &&
       @memory.spotify_album_id.present?
      @memory.error.add(:base, "楽曲とアルバムはどちらか一方を選択してください")
      return false
    end

    if @memory.spotify_track_id.present?
      attach_song
    elsif @memory.spotify_album_id.present?
      attach_album
    else
      true
    end
  end

  def attach_song
    song = Song.find_or_initialize_by(
      spotify_id: @memory.spotify_track_id
    )

    if song.new_record?
      track = fetch_spotify_item(:get_track, song.spotify_id)
      return false unless track

      song.assign_attributes(
        name: track.fetch("name"),
        artist_name: track.fetch("artists").map { |artist| artist["name"] }.join(", "),
        album_name: track.dig("album", "name"),
        image_url: track.dig("album", "images")&.first&.dig("url"),
        spotify_url: track.dig("external_url", "spotify")
      )
    end

    @memory.songs << song
    @selected_music = song
    true
  end

  def attach_album
    album = Album.find_or_initialize_by(
      spotify_id: @memory.spotify_album_id
    )

    if album.new_record?
      item = fetch_spotify_item(:get_album, album.spotify_id)
      return false unless track

      album.assign_attributes(
        name: item.fetch("name"),
        artist_name: item.fetch("artists").map { |artist| artist["name"] }.join(", "),
        release_date: item["release_date"],
        image_url: item["images"]&.first&.dig("url"),
        spotify_url: item.dig("external_url", "spotify")
      )
    end

    @memory.albums << album
    @selected_music = album
    true
  end

  def fetch_spotify_item(method, spotify_id)
    Spotify::Client.new.public_send(method, spotify_id)
  rescue RuntimeError, ArgumentError, KeyError, JSON::ParserError,
         Timeout::Error, SocketError, EOFError,
         SystemCallError, OpenSSL::SSL::SSLError
    @memory.errors.add(
      :base,
      "音楽情報を取得できませんでした。時間をおいて再度お試しください。"
    )
    nil
  end
end
