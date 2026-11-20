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
end
