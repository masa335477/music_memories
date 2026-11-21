class AccountWithdrawalService
  Result = Struct.new(
    :email,
    :notification_sent,
    :notification_error,
    keyword_init: true
  )

  def self.call(user:)
    new(user: user).call
  end

  def initialize(user:)
    @user = user
  end

  def call
    email = @user.email

    # 削除に失敗した場合は例外となり、通知処理には進まない。
    @user.destroy!

    # 通知に失敗しても、アカウントの削除は完了している。
    begin
      notify(email)

      Result.new(email: email, notification_sent: true)
    rescue StandardError => error
      Result.new(
        email: email,
        notification_sent: false,
        notification_error: error
      )
    end
  end

  private

  def notify(email)
    UserMailer.with(email: email).withdrawal_completed.deliver_now
  end
end
