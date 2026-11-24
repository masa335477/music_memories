class AccountsController < ApplicationController
  before_action :require_login
  before_action :set_user

  def edit
  end

  def update
    if @user.update(account_params)
      redirect_to edit_account_path,
                  notice: "アカウント情報を更新しました。",
                  status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def require_login
    return if logged_in?

    redirect_to login_path,
                alert: "アカウント設定を利用するにはログインしてください。"
  end

  def set_user
    @user = current_user
  end

  def account_params
    params.require(:user).permit(:name)
  end
end
