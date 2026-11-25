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

  def withdrawal
  end

  def destroy
    password = params.permit(:current_password)[:current_password]

    unless password.present? && @user.authenticate(password)
      flash.now[:alert] = "現在のパスワードが正しくありません。"
      return render :withdrawal, status: :unprocessable_content
    end

    result = AccountWithdrawalService.call(user: @user)
    reset_session

    unless result.notification_sent
      Rails.logger.warn("退会完了メールの配信に失敗しました (#{result.notification_error.class})")
    end

    redirect_to root_path, notice: "退会しました。", status: :see_other
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
