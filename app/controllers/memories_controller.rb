class MemoriesController < ApplicationController
  before_action :require_login, only: [ :edit, :update, :destroy, :create ]
  before_action :set_owned_memory, only: [ :edit, :update, :destroy ]
  before_action :set_saved_memory_fields, only: [ :edit, :update ]
  before_action :set_tags, only: [ :new, :create, :update, :edit ]

  def index
    filters = params.permit(:q, :tag_id)
    @query = filters[:q].to_s.strip
    @selected_tag_id = filters[:tag_id].presence
    @tags = Tag.order(:name)
    @memories = Memory.search(@query).preload(:user, :songs, :albums, :tags).order(created_at: :desc, id: :desc)
    if @selected_tag_id.present?
      @memories = @memories.where(id: MemoryTag.where(tag_id: @selected_tag_id).select(:memory_id))
    end
    @search_active = @query.present? || @selected_tag_id.present?
  end

  def new
    @memory = Memory.new(
      params.permit(:spotify_track_id, :spotify_album_id)
    )

    attach_music
  end

  def create
    @memory = current_user.memories.build(memory_params)

    music_loaded = false
    memory_saved = false
    saved = false

    Memory.transaction do
      music_loaded = attach_music
      memory_saved = @memory.save if music_loaded

      if music_loaded && memory_saved
        saved = attach_new_tag
      end

      raise ActiveRecord::Rollback unless saved
    end

    if saved
      redirect_to memory_path(@memory), notice: "投稿を作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @memory = Memory.includes(:user, :songs, :albums, :tags).find(params[:id])
    @comments = Comment.where(memory_id: @memory.id).includes(:user).order(created_at: :asc, id: :asc)
    @comment = Comment.new
  end

  def edit
    if params[:spotify_track_id].present?
      @memory.spotify_track_id = params[:spotify_track_id]
      @selected_music = find_selected_music(
        Song, params[:spotify_track_id], :get_track
      )
    elsif params[:spotify_album_id].present?
      @memory.spotify_album_id = params[:spotify_album_id]
      @selected_music = find_selected_music(
        Album, params[:spotify_album_id], :get_album
      )
    else
      @selected_music = @memory.songs.first || @memory.albums.first

      if @selected_music.is_a?(Song)
        @memory.spotify_track_id = @selected_music.spotify_id
      elsif @selected_music.is_a?(Album)
        @memory.spotify_album_id = @selected_music.spotify_id
      end
    end
    return if @selected_music.present?

    redirect_to memory_path(@memory),
                alert: "音楽情報を取得できませんでした。"
  end

  def update
    music_loaded = false
    saved = false

    Memory.transaction do
      @memory.assign_attributes(memory_params)

      music_loaded = replace_music
      if music_loaded && @memory.save
        saved = attach_new_tag
      end

      raise ActiveRecord::Rollback unless saved
    end

    if saved
      redirect_to memory_path(@memory), notice: "投稿を更新しました。"
    else
      @selected_music ||= @memory.songs.first || @memory.albums.first
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @memory.destroy
      redirect_to memories_path,
                  notice: "投稿を削除しました。",
                  status: :see_other
    else
      redirect_to memory_path(@memory),
                  alert: "投稿を削除できませんでした。",
                  status: :see_other
    end
  end

  private

  def set_saved_memory_fields
    @saved_memory_fields = {
      title: @memory.title.to_s,
      body: @memory.body.to_s,
      spotify_track_id: @memory.songs.first&.spotify_id.to_s,
      spotify_album_id: @memory.albums.first&.spotify_id.to_s,
      tag_ids: @memory.tag_ids.map(&:to_s).sort
    }
  end

  def require_login
    return if logged_in?

    redirect_to login_path, alert: "投稿するにはログインしてください。"
  end

  def set_tags
    @tags = Tag.order(:name)
  end

  def attach_new_tag
    name = @memory.new_tag_name.to_s.strip

    return true if name.blank?

    tag = Tag.find_or_initialize_by(name: name)

    unless tag.valid?
      @memory.errors.add(
        :base,
        "新しいタグ名を確認してください（30文字以内）。"
      )

      return false
    end

    @memory.tags << tag unless @memory.tags.include?(tag)

    true
  end

  def set_owned_memory
    @memory = current_user.memories.find_by(id: params[:id])
    return if @memory

    redirect_to memories_path, alert: "指定された投稿は存在しないか、操作する権限がありません。"
  end

  def memory_params
    params.require(:memory).permit(
      :title,
      :body,
      :spotify_track_id,
      :spotify_album_id,
      :new_tag_name,
      tag_ids: []
    )
  end

  def attach_music
    if @memory.spotify_track_id.present? &&
       @memory.spotify_album_id.present?
      @memory.errors.add(:base, "楽曲とアルバムはどちらか一方を選択してください")
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
      item = fetch_spotify_item(:get_track, song.spotify_id)
      return false unless item

      song.assign_attributes(
        name: item.fetch("name"),
        artist_name: item.fetch("artists").map { |artist| artist["name"] }.join(", "),
        album_name: item.dig("album", "name"),
        image_url: item.dig("album", "images")&.first&.dig("url"),
        spotify_url: item.dig("external_urls", "spotify")
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
      return false unless item

      album.assign_attributes(
        name: item.fetch("name"),
        artist_name: item.fetch("artists").map { |artist| artist["name"] }.join(", "),
        release_date: item["release_date"],
        image_url: item["images"]&.first&.dig("url"),
        spotify_url: item.dig("external_urls", "spotify")
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


  def find_selected_music(model, spotify_id, spotify_method)
    music = model.find_by(spotify_id: spotify_id)
    return music if music

    item = fetch_spotify_item(spotify_method, spotify_id)
    return nil unless item

    if model == Song
      Song.new(
        spotify_id: spotify_id,
        name: item.fetch("name"),
        artist_name: item.fetch("artists").map { |artist| artist["name"] }.join(", "),
        album_name: item.dig("album", "name"),
        image_url: item.dig("album", "images")&.first&.dig("url"),
        spotify_url: item.dig("external_urls", "spotify")
      )
    else
      Album.new(
        spotify_id: spotify_id,
        name: item.fetch("name"),
        artist_name: item.fetch("artists").map { |artist| artist["name"] }.join(", "),
        release_date: item["release_date"],
        image_url: item["images"]&.first&.dig("url"),
        spotify_url: item.dig("external_urls", "spotify")
      )
    end
  end


  def replace_music
    if @memory.spotify_track_id.present? &&
       @memory.spotify_album_id.present?
      @memory.errors.add(:base, "楽曲とアルバムはどちらか一方を選択してください")
      return false
    end

    if @memory.spotify_track_id.present?
      @selected_music = find_selected_music(
        Song, @memory.spotify_track_id, :get_track
      )
    elsif @memory.spotify_album_id.present?
      @selected_music = find_selected_music(
        Album, @memory.spotify_album_id, :get_album
      )
    else
      @selected_music = @memory.songs.first || @memory.albums.first
    end

    unless @selected_music
      @memory.errors.add(:base, "楽曲またはアルバムを選択してください") if @memory.errors.empty?
      return false
    end

    if @selected_music.is_a?(Song)
      @memory.albums = []
      @memory.songs = [ @selected_music ]
    else
      @memory.songs = []
      @memory.albums = [ @selected_music ]
    end

    true
  end
end
