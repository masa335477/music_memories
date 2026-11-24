require "application_system_test_case"

class HomesTest < ApplicationSystemTestCase
  test "ホーム画面が正常に表示される" do
    visit root_url

    assert_text "好きな音楽に、あなたの言葉を。"
    assert_text "Music Memoriesでできること"
    assert_link "新規登録", href: sign_up_path
    assert_link "無料で始める", href: sign_up_path
  end
end
