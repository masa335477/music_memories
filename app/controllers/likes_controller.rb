class LikesController < ApplicationController
  before_action :require_login
  before_action :set_memory

  def create
    current_user.likes.create_or_find_by!(memory: @memory)

    redirect_to memory_path(@memory),
                notice: "共感しました。",
                status: :see_other
  end

  def destroy
    current_user.likes.find_by(memory: @memory)&.destroy!

    redirect_to memory_path(@memory),
                notice: "共感を取り消しました。",
                status: :see_other
  end

  private

  def require_login
    return if logged_in?

    redirect_to login_path,
                alert: "共感するにはログインしてください。"
  end

  def set_memory
    @memory = Memory.find(params[:memory_id])
  end
end
