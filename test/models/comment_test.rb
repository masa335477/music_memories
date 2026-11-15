require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    @memory = FactoryBot.create(:memory, user: @user)
  end

  test "正常なコメントは有効" do
    comment = Comment.new(
      user: @user,
      memory: @memory,
      body: "この曲のメロディーが好きです！"
    )

    assert comment.valid?
  end

  test "本文が空欄の場合は無効" do
    comment = Comment.new(user: @user, memory: @memory, body: "")

    assert_not comment.valid?
    assert comment.errors[:body].any?
  end

  test "本文が空白のみの場合は無効" do
    comment = Comment.new(user: @user, memory: @memory, body: "   ")

    assert_not comment.valid?
  end

  test "本文が1000文字の場合は有効" do
    comment = Comment.new(user: @user, memory: @memory, body: "あ" * 1000)

    assert comment.valid?
  end

  test "本文が1001文字の場合は無効" do
    comment = Comment.new(user: @user, memory: @memory, body: "あ" * 1001)

    assert_not comment.valid?
    assert comment.errors[:body].any?
  end

  test "ユーザーが存在しない場合は無効" do
    comment = Comment.new(user: nil, memory: @memory, body: "コメント")

    assert_not comment.valid?
    assert comment.errors[:user].any?
  end

  test "投稿が存在しない場合は無効" do
    comment = Comment.new(user: @user, memory: nil, body: "コメント")

    assert_not comment.valid?
    assert comment.errors[:memory].any?
  end
end
