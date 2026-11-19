class TagsController < ApplicationController
  def show
    @tag = Tag.find(params[:id])

    @memories = @tag.memories
                    .includes(:user, :songs, :albums, :tags)
                    .order(created_at: :desc, id: :desc)
  end
end
