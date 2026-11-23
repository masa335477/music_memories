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

    if @memory.spotify_track_id.present? &&
       @memory.spotify_album_id.present?
      @memory.errors.add(
        :base,
        "楽曲とアルバムはどちらか一方を選択してください"
      )
    elsif @memory.spotify_track_id.present?
      @selected_music = find_selected_music(
        Song, @memory.spotify_track_id, :get_track
      )
    elsif @memory.spotify_album_id.present?
      @selected_music = find_selected_music(
        Album, @memory.spotify_album_id, :get_album
      )
    end
  end

  def create
    @memory = current_user.memories.build(memory_params)

    service = Memories::SaveService.new(memory: @memory)
    saved = service.create
    @selected_music = service.selected_music

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
    service = Memories::SaveService.new(memory: @memory)
    saved = service.update(memory_params)
    @selected_music = service.selected_music

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

  def find_selected_music(model, spotify_id, _spotify_method)
    Memories::MusicResolver.new(memory: @memory).resolve(
      model: model,
      spotify_id: spotify_id
    )
  end
end
