class UserMailer < ApplicationMailer
  def registration_completed
    user = params[:user]

    mail(
      from: ENV.fetch("MAILER_FROM", "no-reply@example.test"),
      to: user.email,
      subject: "【Music Memories】ユーザー登録完了のお知らせ"
    )
  end
end
