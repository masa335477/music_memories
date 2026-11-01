require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "テストユーザー",
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "ログイン画面を表示できる" do
    get login_url
    assert_response :success
  end

  test "正しいメールアドレスとパスワードでログインできる" do
    post login_url, params: {
      session: {
        email: @user.email,
        password: "password123"
      }
    }

    assert_redirected_to root_url

    follow_redirect!
    assert_response :success
    assert_select ".home-user-name", text: /テストユーザー/
  end

  test "間違ったパスワードではログインできない" do
    post login_url, params: {
      session: {
        email: @user.email,
        password: "wrongpassword"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".flash-message.alert",
                  text: /メールアドレスまたはパスワードが正しくありません/
  end

  test "存在しないメールアドレスではログインできない" do
    post login_url, params: {
      session: {
        email: "unknown@example.com",
        password: "password123"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".flash-message.alert",
                  text: /メールアドレスまたはパスワードが正しくありません/
  end

  test "ログアウトするとログイン状態が解除される" do
    post login_url, params: {
      session: {
        email: @user.email,
        password: "password123"
      }
    }

    assert_redirected_to root_url

    delete logout_url
    assert_redirected_to root_url

    follow_redirect!
    assert_response :success
    assert_select ".home-user-name", count: 0
    assert_select "a[href='#{login_path}']"
  end
end
