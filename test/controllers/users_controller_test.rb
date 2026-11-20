require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "新規登録画面が正常に表示されること" do
    get sign_up_url
    assert_response :success
  end

  test "新規登録に成功すると登録完了メールがキューに追加されること" do
    assert_emails 1 do
      post sign_up_url, params: {
        user: {
          name: "テストユーザー",
          email: "registration-test@example.test",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_redirected_to root_url
  end

  test "新規登録に失敗するとメールがキューに追加されないこと" do
    assert_no_enqueued_emails do
      post sign_up_url, params: {
        user: {
          name: "テストユーザー",
          email: "registration-test@example.test",
          password: "password123",
          password_confirmation: "different-password"
        }
      }
    end

    assert_response 422
  end
end
