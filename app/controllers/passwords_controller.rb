class PasswordsController < ApplicationController
  rate_limit to: 5, within: 10.minutes, only: :create

  before_action :set_reset_user, only: [ :edit, :update ]

  def new
  end

  def create
    email = params.permit(:email)[:email].to_s.strip
    PasswordResetEmailJob.perform_later(email) if email.present?

    redirect_to new_password_reset_path, status: :see_other,
      notice: "登録済みのメールアドレスであれば、再設定リンクをお送りします。"
  end

  def edit
  end

  def update
    attributes = params.permit(:password, :password_confirmation)

    if attributes[:password].blank? || attributes[:password_confirmation].blank?
      flash.now[:alert] = "新しいパスワードと確認欄を入力してください。"
      return render :edit, status: :unprocessable_content
    end

    updated = @user.with_lock do
      next :invalid_token unless User.find_by_password_reset_token(@token)

      @user.update(attributes)
    end

    return redirect_to_invalid_link if updated == :invalid_token

    if updated
      reset_session
      redirect_to login_path, status: :see_other,
        notice: "パスワードを変更しました。新しいパスワードでログインしてください。"
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence(locale: :ja)
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_reset_user
    response.set_header("Referrer-Policy", "no-referrer")
    response.set_header("Cache-Control", "no-store")

    @token = params.permit(:token)[:token]
    @user = User.find_by_password_reset_token(@token) if @token.is_a?(String)
    redirect_to_invalid_link unless @user
  end

  def redirect_to_invalid_link
    redirect_to new_password_reset_path, status: :see_other,
      alert: "再設定リンクが無効か、有効期限が切れています。もう一度メールをリクエストしてください。"
  end
end
