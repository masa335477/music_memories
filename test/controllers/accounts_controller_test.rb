require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, name: "変更前の名前")
  end

  test "未ログインでは設定画面を開けないこと" do
    get edit_account_url

    assert_redirected_to login_url
  end

  test "未ログインではユーザー名を変更できないこと" do
    patch account_url, params: {
      user: { name: "変更後の名前" }
    }

    assert_redirected_to login_url
    assert_equal "変更前の名前", @user.reload.name
  end

  test "自分の情報とパスワード再設定へのリンクを表示すること" do
    login_as(@user)

    get edit_account_url

    assert_response :success
    assert_select "input[name='user[name]'][value=?]", @user.name
    assert_select ".account-email p", text: @user.email
    assert_select "a[href=?]", new_password_reset_path
    assert_select "a[href=?]", edit_account_path,
                  text: "アカウント設定"
  end

  test "ユーザー名を更新できること" do
    login_as(@user)

    patch account_url, params: {
      user: { name: "変更後の名前" }
    }

    assert_redirected_to edit_account_url
    assert_equal "変更後の名前", @user.reload.name
    assert_equal "アカウント情報を更新しました。", flash[:notice]

    follow_redirect!
    assert_select "input[name='user[name]'][value=?]", "変更後の名前"
  end

  test "ユーザー名が空欄なら保存せずエラーを表示すること" do
    login_as(@user)

    patch account_url, params: {
      user: { name: "" }
    }

    assert_response :unprocessable_entity
    assert_equal "変更前の名前", @user.reload.name
    assert_select ".account-errors li", minimum: 1
  end

  test "別ユーザーのIDを送信しても更新対象は自分になること" do
    other_user = create(:user, name: "別ユーザー")
    login_as(@user)

    patch account_url, params: {
      id: other_user.id,
      user: {
        id: other_user.id,
        name: "変更後の名前"
      }
    }

    assert_redirected_to edit_account_url
    assert_equal "変更後の名前", @user.reload.name
    assert_equal "別ユーザー", other_user.reload.name
  end

  test "メールアドレスとパスワードを送信しても変更されないこと" do
    original_email = @user.email
    original_password_digest = @user.password_digest
    login_as(@user)

    patch account_url, params: {
      user: {
        name: "変更後の名前",
        email: "changed@example.test",
        password: "new-password123",
        password_confirmation: "new-password123"
      }
    }

    assert_redirected_to edit_account_url
    @user.reload
    assert_equal "変更後の名前", @user.name
    assert_equal original_email, @user.email
    assert_equal original_password_digest, @user.password_digest
  end

  private

  def login_as(user)
    post login_url, params: {
      session: {
        email: user.email,
        password: "password123"
      }
    }

    assert_redirected_to root_url
  end
end
