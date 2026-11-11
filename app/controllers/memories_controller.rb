class MemoriesController < ApplicationController
  def index
    @memories = Memory.includes(:user, :songs, :albums).order(created_at: :desc, id: :desc)
  end

  def show
    @memory = Memory.includes(:user, :songs, :albums).find(params[:id])
  end
end
