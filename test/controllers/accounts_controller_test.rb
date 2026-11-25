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
    assert_select "a[href=?]", edit_account_path, text: "アカウント設定"
    assert_select "a[href=?]", withdrawal_account_path, text: "退会手続きへ進む"
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

  test "退会の確認を開いてもアカウントは削除されないこと" do
    login_as(@user)

    assert_no_difference "User.count" do
      get withdrawal_account_url
    end

    assert_response :success
    assert_select "form[action=?] input[type=password][name=current_password]", account_path
  end

  test "未ログインでは退会画面の閲覧や退会ができないこと" do
    get withdrawal_account_url
    assert_redirected_to login_url

    assert_no_difference "User.count" do
      delete account_url, params: { current_password: "password123" }
    end

    assert_redirected_to login_url
  end

  test "パスワードが正しくない場合は退会できないこと" do
    login_as(@user)

    assert_no_difference "User.count" do
      delete account_url, params: { current_password: "incorrect-password" }
    end

    assert_response :unprocessable_content
    assert_select ".flash-message.alert", text: "現在のパスワードが正しくありません。"
  end

  test "本人だけが関連データとともに退会しログアウトすること" do
    memory = create(:memory, user: @user)
    other_memory = create(:memory)
    comment = create(:comment, user: @user, memory: other_memory)
    like = create(:like, user: @user, memory: other_memory)
    interest = create(:listening_interest, user: @user, memory: other_memory)
    login_as(@user)

    assert_difference "User.count", -1 do
      delete account_url, params: { id: other_memory.user_id, current_password: "password123" }
    end

    assert_redirected_to root_url
    assert_not User.exists?(@user.id)
    assert User.exists?(other_memory.user_id)
    assert Memory.exists?(other_memory.id)
    assert_not Memory.exists?(memory.id)
    assert_not Comment.exists?(comment.id)
    assert_not Like.exists?(like.id)
    assert_not ListeningInterest.exists?(interest.id)

    follow_redirect!
    assert_select ".flash-message.notice", text: "退会しました。"
    get edit_account_url
    assert_redirected_to login_url
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
