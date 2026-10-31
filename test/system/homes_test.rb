require "application_system_test_case"

class HomesTest < ApplicationSystemTestCase
  test "ホーム画面が正常に表示される" do
    visit root_path

    assert_selector "h1", text: "Music Memories"
    assert_text "音楽を通じて思い出を共有するサービスです。"
    assert_text "現在サービスを開発中です。完成まで今しばらくお待ちください。"
  end
end
