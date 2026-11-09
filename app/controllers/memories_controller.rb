class MemoriesController < ApplicationController
  def index
    @memories = Memory.includes(:user, :songs, :albums).order(created_at: :desc, id: :desc)
  end
end
