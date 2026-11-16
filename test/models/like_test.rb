require "test_helper"

class LikeTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    @memory = FactoryBot.create(:memory, user: @user)
  end

  test "共感を登録できる" do
    like = Like.new(user: @user, memory: @memory)

    assert like.valid?
  end

  test "同じユーザーは同じ投稿に重複登録できない" do
    Like.create!(user: @user, memory: @memory)

    duplicate = Like.new(user: @user, memory: @memory)

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :user_id
  end

  test "異なるユーザーは同じ投稿に登録できる" do
    other_user = FactoryBot.create(:user)
    Like.create!(user: @user, memory: @memory)

    like = Like.new(user: other_user, memory: @memory)

    assert like.valid?
  end

  test "同じユーザーは異なる投稿に登録できる" do
    other_memory = FactoryBot.create(:memory, user: @user)
    Like.create!(user: @user, memory: @memory)

    like = Like.new(user: @user, memory: other_memory)

    assert like.valid?
  end
end
