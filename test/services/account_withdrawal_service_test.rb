require "test_helper"

class AccountWithdrawalServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "アカウントを削除して退会完了メールを送信する" do
    user = User.create!(
      name: "退会テスト",
      email: "withdrawal-service@example.test",
      password: "password"
    )
    user_id = user.id
    email = user.email
    result = nil

    assert_difference "User.count", -1 do
      assert_emails 1 do
        result = AccountWithdrawalService.call(user: user)
      end
    end

    assert_not User.exists?(user_id)
    assert result.notification_sent
    assert_nil result.notification_error
    assert_equal [ email ], ActionMailer::Base.deliveries.last.to
  end

  test "削除に失敗した場合は退会完了メールを送信しない" do
    user = User.new(email: "withdrawal-failure@example.test")

    user.define_singleton_method(:destroy!) do
      raise ActiveRecord::RecordNotDestroyed, "削除できませんでした"
    end

    assert_no_emails do
      assert_raises ActiveRecord::RecordNotDestroyed do
        AccountWithdrawalService.call(user: user)
      end
    end
  end

  test "メール送信に失敗しても削除済みであることを確認できる" do
    user = User.create!(
      name: "通知失敗テスト",
      email: "withdrawal-notification-failure@example.test",
      password: "password"
    )
    user_id = user.id

    failing_service = Class.new(AccountWithdrawalService) do
      private

      def notify(_email)
        raise IOError, "メール送信に失敗しました"
      end
    end

    result = failing_service.call(user: user)

    assert_not User.exists?(user_id)
    assert_not result.notification_sent
    assert_instance_of IOError, result.notification_error
    assert_equal user.email, result.email
  end
end
