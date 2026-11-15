require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "テストユーザー",
      email: "comment-user@example.com",
      password: "password123"
    )

    @other_user = User.create!(
      name: "別のユーザー",
      email: "other-comment-user@example.com",
      password: "password123"
    )

    @memory = Memory.new(
      user: @user,
      title: "お気に入りのアルバム",
      body: "このアルバムが大好きです。"
    )

    @memory.songs << Song.create!(
      spotify_id: "test-comment-track",
      name: "テスト楽曲",
      artist_name: "テストアーティスト"
    )
    @memory.save!

    @comment = Comment.create!(
      user: @user,
      memory: @memory,
      body: "素晴らしい楽曲ですね！"
    )
  end

  test "ログイン中のユーザーはコメントを投稿できる" do
    login_as(@other_user)

    assert_difference("Comment.count", 1) do
      post memory_comments_path(@memory), params: {
        comment: { body: "自分もその曲大好き！" }
      }
    end

    assert_redirected_to memory_path(@memory)

    comment = Comment.last
    assert_equal @other_user.id, comment.user_id
    assert_equal @memory.id, comment.memory_id
    assert_equal "自分もその曲大好き！", comment.body
  end

  test "未ログインユーザーはコメントを投稿できない" do
    assert_no_difference("Comment.count") do
      post memory_comments_path(@memory), params: {
        comment: { body: "私はコメントできないですか？" }
      }
    end

    assert_redirected_to login_path
  end

  test "空欄のコメントは投稿できない" do
    login_as(@user)

    assert_no_difference("Comment.count") do
      post memory_comments_path(@memory), params: {
        comment: { body: "" }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors", text: /入力してください/
  end

  test "1000文字を超えるコメントは投稿できない" do
    login_as(@user)

    assert_no_difference("Comment.count") do
      post memory_comments_path(@memory), params: {
        comment: { body: "あ" * 1001 }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors", text: /1000文字以内/
  end

  test "自分のコメントを削除できる" do
    login_as(@user)

    assert_difference("Comment.count", -1) do
      delete comment_path(@comment)
    end

    assert_redirected_to memory_path(@memory)
    assert_nil Comment.find_by(id: @comment.id)
  end

  test "他人のコメントは削除できない" do
    login_as(@other_user)

    assert_no_difference("Comment.count") do
      delete comment_path(@comment)
    end

    assert_redirected_to memories_path
    assert_equal(
      "コメントが存在しないか、削除する権限がありません。",
      flash[:alert]
    )

    assert Comment.exists?(@comment.id)
  end

  test "未ログインユーザーはコメントを削除できない" do
    assert_no_difference("Comment.count") do
      delete comment_path(@comment)
    end

    assert_redirected_to login_path
    assert Comment.exists?(@comment.id)
  end

  private

  def login_as(user)
    post login_path, params: {
      session: {
        email: user.email,
        password: "password123"
      }
    }

    assert_redirected_to root_path
  end
end
