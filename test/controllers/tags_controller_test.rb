require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  test "未ログインでもタグ別投稿一覧を閲覧できる" do
    tag = create(:tag, name: "ロック")
    memory = create(:memory)
    memory.tags << tag

    get tag_path(tag)

    assert_response :success
    assert_select ".memories-page-title", text: /ロック/
    assert_select "article.memory-card h2 a", text: memory.title
  end

  test "指定したタグが付いた投稿だけを表示する" do
    rock_tag = create(:tag, name: "ロック")
    pop_tag = create(:tag, name: "ポップス")

    rock_memory = create(:memory, title: "ロックの投稿")
    pop_memory = create(:memory, title: "ポップスの投稿")

    rock_memory.tags << rock_tag
    pop_memory.tags << pop_tag

    get tag_path(rock_tag)

    assert_response :success
    assert_select "article.memory-card", count: 1
    assert_select "article.memory-card h2 a", text: rock_memory.title
    assert_select "article.memory-card h2 a", text: pop_memory.title, count: 0
  end

  test "関連する投稿がない場合は案内を表示する" do
    tag = create(:tag, name: "名盤")

    get tag_path(tag)

    assert_response :success
    assert_select ".memories-empty",
                  text: /このタグが付いた投稿はまだありません。/
    assert_select "article.memory-card", count: 0
  end

  test "存在しないタグIDでは404を返す" do
    get tag_path(id: 999_999_999)

    assert_response :not_found
  end
end
