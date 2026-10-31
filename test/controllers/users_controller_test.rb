require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "新規登録画面が正常に表示されること" do
    get sign_up_url
    assert_response :success
  end
end
