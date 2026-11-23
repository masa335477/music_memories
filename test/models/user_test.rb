require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "パスワードが6文字のユーザーを保存できる" do
    user = build(:user, password: "abc123")

    assert user.save!
  end

  test "名前が空欄の場合は無効" do
    user = build(:user, name: "")

    assert_not user.valid?
    assert user.errors.of_kind?(:name, :blank)
  end

  test "メールアドレスが空欄の場合は無効" do
    user = build(:user, email: "")

    assert_not user.valid?
    assert user.errors.of_kind?(:email, :blank)
  end

  test "登録済みのメールアドレスは使えない" do
    registered_user = create(:user)
    user = build(:user, email: registered_user.email)

    assert_not user.valid?
    assert user.errors.of_kind?(:email, :taken)
  end

  test "新規登録時にパスワードが未入力の場合は無効" do
    user = build(:user, password: nil)

    assert_not user.valid?
    assert user.errors.of_kind?(:password, :blank)
  end

  test "パスワードが5文字の場合は無効" do
    user = build(:user, password: "ab123")

    assert_not user.valid?
    assert user.errors.of_kind?(:password, :too_short)
  end

  test "パスワードと確認入力が一致しない場合は無効" do
    user = build(:user, password: "password123", password_confirmation: "different123")

    assert_not user.valid?
    assert user.errors.of_kind?(:password_confirmation, :confirmation)
  end

  test "パスワードを再入力せずに登録済みユーザーの名前を更新できる" do
    user = User.find(create(:user, password: "password123").id)

    assert user.update(name: "変更後の名前")
    assert_equal "変更後の名前", user.reload.name
    assert_equal user, user.authenticate("password123")
  end

  test "正しいパスワードで認証するとユーザーを返す" do
    user = create(:user, password: "password123").reload

    assert_equal user, user.authenticate("password123")
  end

  test "間違ったパスワードで認証するとfalseを返す" do
    user = create(:user, password: "password123").reload

    assert_equal false, user.authenticate("different123")
  end

  test "有効なパスワード再設定トークンから発行先のユーザーを取得できる" do
    user = create(:user)
    token = user.password_reset_token

    assert_equal user, User.find_by_password_reset_token(token)
  end

  test "パスワード再設定トークンは発行から15分を超えると使えない" do
    user = create(:user)

    freeze_time do
      token = user.password_reset_token

      travel 14.minutes
      assert_equal user, User.find_by_password_reset_token(token)

      travel 2.minutes
      assert_nil User.find_by_password_reset_token(token)
    end
  end

  test "パスワードを変更すると発行済みの再設定トークンは使えない" do
    user = create(:user, password: "password123")
    token = user.password_reset_token

    user.update!(password: "newpassword123")

    assert_nil User.find_by_password_reset_token(token)
  end
end
