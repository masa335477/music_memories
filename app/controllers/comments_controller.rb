class CommentsController < ApplicationController
  before_action :require_login, only: [ :create, :destroy ]

  def create
    @memory = Memory.find(params[:memory_id])
    @comment = @memory.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to memory_path(@memory), notice: "コメントを投稿しました。"
    else
      @comments = Comment.where(memory_id: @memory.id).includes(:user).order(created_at: :asc, id: :asc)
      render "memories/show", status: :unprocessable_entity
    end
  end

  def destroy
    @comment = current_user.comments.find_by(id: params[:id])

    unless @comment
      redirect_to memories_path, alert: "コメントが存在しないか、削除する権限がありません。"
      return
    end

    @memory = @comment.memory
    @comment.destroy!

    redirect_to memory_path(@memory),
                notice: "コメントを削除しました。",
                status: :see_other
  end

  private

  def require_login
    return if logged_in?
    redirect_to login_path, alert: "コメントするにはログインしてください。"
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
