require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "登録完了メールに正しい宛先とログインリンクが設定されること" do
    user = User.new(email: "registration-test@example.test")
    mail = UserMailer.with(user: user).registration_completed

    assert_equal [ user.email ], mail.to
    assert_equal "【Music Memories】ユーザー登録完了のお知らせ", mail.subject
    assert_includes mail.body.decoded, "ユーザー登録が完了しました。"
    assert_match %r{href="https?://[^"/]+/login"}, mail.body.decoded
  end

  test "退会完了メールに正しい宛先と件名と本文が設定されること" do
    email = "withdrawal-test@example.test"
    mail = UserMailer.with(email: email).withdrawal_completed

    assert_equal [ email ], mail.to
    assert_equal "【Music Memories】退会手続き完了のお知らせ", mail.subject
    assert_includes mail.body.decoded, "退会手続きが完了しました"
    assert_includes mail.body.decoded, "登録情報を削除しました。"
  end
end
