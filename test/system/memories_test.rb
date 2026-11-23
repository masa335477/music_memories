require "application_system_test_case"

class MemoriesTest < ApplicationSystemTestCase
  test "楽曲を検索して投稿し、一覧から詳細を開いて編集・削除できる" do
    user = create(:user, password: "password123")
    title = "夜に聴きたい一曲"
    updated_title = "雨の夜に聴きたい一曲"
    track = {
      "id" => "system-test-track",
      "name" => "テスト楽曲",
      "artists" => [ { "name" => "テストアーティスト" } ],
      "album" => { "name" => "テストアルバム" }
    }

    visit login_path
    log_in(user)

    with_spotify_track(track) do
      within ".site-header" do
        click_link "＋ 投稿する"
      end
      click_link "楽曲を検索する"
      fill_in "楽曲名・アーティスト名を入力", with: track.fetch("name")
      click_button "検索", exact: true
      within ".search-card", text: track.fetch("name") do
        click_link "この楽曲で投稿する"
      end
      assert_selector ".memory-compose-music h3", text: track.fetch("name")

      fill_in "memory_title", with: title
      fill_in "memory_body", with: "夜に散歩しながらよく聴いた曲です。"
      fill_in "新しいタグを作成（任意）", with: "夜の散歩"
      click_button "投稿する →"
      assert_text "投稿を作成しました。"
    end

    click_link "← 投稿一覧に戻る"
    assert_current_path memories_path
    within ".memory-card", text: title do
      click_link "投稿詳細を見る"
    end
    assert_selector ".memory-detail h2", text: title, exact_text: true
    assert_text "夜に散歩しながらよく聴いた曲です。"

    click_link "#夜の散歩"
    assert_selector "h1", text: "#夜の散歩 の投稿"
    click_link title, exact: true

    click_link "編集する"
    fill_in "memory_title", with: updated_title
    fill_in "memory_body", with: "雨の夜にも聴きたくなる曲です。"
    click_button "更新する →"
    assert_text "投稿を更新しました。"
    assert_selector ".memory-detail h2", text: updated_title, exact_text: true
    assert_text "雨の夜にも聴きたくなる曲です。"

    accept_confirm "この投稿を削除しますか？この操作は取り消せません。" do
      click_button "削除する"
    end
    assert_current_path memories_path
    assert_text "投稿を削除しました。"
    assert_no_selector ".memory-card", text: updated_title
  end

  test "公開投稿を閲覧し、ログインしてコメントとリアクションを操作できる" do
    memory = create(:memory)
    user = create(:user, password: "password123")
    comment = "私もこの曲を聴いてみたいです。"

    visit root_path
    within ".site-header" do
      click_link "みんなの投稿"
    end
    within ".memory-card", text: memory.title do
      click_link "投稿詳細を見る"
    end
    assert_current_path memory_path(memory)
    assert_button "共感", exact: true, disabled: true
    assert_button "聴いてみたい", exact: true, disabled: true
    assert_no_field "コメント"
    click_link "ログインはこちら"
    log_in(user)

    within ".site-header" do
      click_link "みんなの投稿"
    end
    within ".memory-card", text: memory.title do
      click_link "投稿詳細を見る"
    end
    fill_in "コメント", with: comment
    click_button "コメントする"
    assert_selector ".comment-card", text: comment
    accept_confirm "このコメントを削除しますか？" do
      within ".comment-card", text: comment do
        click_button "削除する"
      end
    end
    assert_no_selector ".comment-card", text: comment

    click_button "共感", exact: true
    assert_text "共感：1件"
    click_button "共感を取り消す"
    assert_text "共感：0件"

    click_button "聴いてみたい", exact: true
    assert_text "聴いてみたい：1件"
    click_button "聴いてみたいを解除"
    assert_text "聴いてみたい：0件"

    within ".site-header" do
      click_button "ログアウト"
      assert_link "ログイン", exact: true
    end
    visit memory_path(memory)
    assert_button "共感", exact: true, disabled: true
    assert_no_field "コメント"
  end

  private

  def log_in(user)
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン", exact: true
    assert_selector ".home-user-name", text: "#{user.name}さん"
  end

  def with_spotify_track(track)
    client = Object.new
    client.define_singleton_method(:search_tracks) do |query, **_options|
      items = query == track.fetch("name") ? [ track ] : []
      { "items" => items, "total" => items.size }
    end
    client.define_singleton_method(:get_track) do |spotify_id|
      raise KeyError, spotify_id unless spotify_id == track.fetch("id")

      track
    end

    client_class = Spotify::Client.singleton_class
    original_new = Spotify::Client.method(:new)
    client_class.define_method(:new) { client }
    begin
      yield
    ensure
      client_class.define_method(:new, original_new)
    end
  end
end
