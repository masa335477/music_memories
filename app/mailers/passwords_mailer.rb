class PasswordsMailer < ApplicationMailer
  def reset
    user = params[:user]
    @reset_url = edit_password_reset_url(token: user.password_reset_token)

    mail(
      from: ENV.fetch("MAILER_FROM", "no-reply@example.test"),
      to: user.email,
      subject: "【Music Memories】パスワード再設定のご案内"
    )
  end
end
