module Memories
  class SaveService
    attr_reader :selected_music

    def initialize(memory:)
      @memory = memory
      @selected_music = nil
    end

    def create
      saved = false

      Memory.transaction do
        music_loaded = attach_music
        memory_saved = @memory.save if music_loaded

        saved = attach_new_tag if music_loaded && memory_saved

        raise ActiveRecord::Rollback unless saved
      end

      saved
    end

    def update(attributes)
      saved = false

      Memory.transaction do
        @memory.assign_attributes(attributes)

        music_loaded = replace_music

        if music_loaded && @memory.save
          saved = attach_new_tag
        end

        raise ActiveRecord::Rollback unless saved
      end

      saved
    end

    private

    def attach_music
      if @memory.spotify_track_id.present? &&
         @memory.spotify_album_id.present?
        @memory.errors.add(
          :base,
          "楽曲とアルバムはどちらか一方を選択してください"
        )
        return false
      end

      if @memory.spotify_track_id.present?
        attach_selected_music(
          Song, @memory.spotify_track_id
        )
      elsif @memory.spotify_album_id.present?
        attach_selected_music(
          Album, @memory.spotify_album_id
        )
      else
        true
      end
    end

    def attach_selected_music(model, spotify_id)
      music = resolve_music(model, spotify_id)
      return false unless music

      if music.is_a?(Song)
        @memory.songs << music
      else
        @memory.albums << music
      end

      @selected_music = music
      true
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

    def replace_music
      if @memory.spotify_track_id.present? &&
         @memory.spotify_album_id.present?
        @memory.errors.add(
          :base,
          "楽曲とアルバムはどちらか一方を選択してください"
        )
        return false
      end

      if @memory.spotify_track_id.present?
        @selected_music = resolve_music(
          Song, @memory.spotify_track_id
        )
      elsif @memory.spotify_album_id.present?
        @selected_music = resolve_music(
          Album, @memory.spotify_album_id
        )
      else
        @selected_music = @memory.songs.first || @memory.albums.first
      end

      unless @selected_music
        if @memory.errors.empty?
          @memory.errors.add(
            :base,
            "楽曲またはアルバムを選択してください"
          )
        end
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

    def resolve_music(model, spotify_id)
      Memories::MusicResolver.new(memory: @memory).resolve(
        model: model,
        spotify_id: spotify_id
      )
    end
  end
end
