require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "未ログインで利用規約を表示できる" do
    get terms_path

    assert_response :success
    assert_select "h1", text: "利用規約"
  end

  test "未ログインでプライバシーポリシーを表示できる" do
    get privacy_path

    assert_response :success
    assert_select "h1", text: "プライバシーポリシー"
  end

  test "利用規約ページに共通ヘッダーとフッターを表示する" do
    get terms_path

    assert_select ".site-header a[href=?]", root_path,
                  text: "Music Memories"
    assert_select ".site-footer a[href=?]", terms_path,
                  text: "利用規約"
    assert_select ".site-footer a[href=?]", privacy_path,
                  text: "プライバシーポリシー"
    assert_select ".site-footer small",
                  text: "© #{Date.current.year} Music Memories"
  end

  test "登録フォーム内に利用規約とプライバシーポリシーへのリンクを表示する" do
    get sign_up_path

    assert_response :success
    assert_select "form .signup-legal" do
      assert_select "a[href=?]", terms_path, text: "利用規約"
      assert_select "a[href=?]", privacy_path,
                    text: "プライバシーポリシー"
    end
  end
end
