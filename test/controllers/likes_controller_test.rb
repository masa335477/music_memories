require "test_helper"

class LikesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = FactoryBot.create(:user)
    @other_user = FactoryBot.create(:user)
    @memory = FactoryBot.create(:memory, user: @user)
  end

  test "ログイン中のユーザーは共感を登録できる" do
    login_as(@user)

    assert_difference("Like.count", 1) do
      post memory_like_path(@memory)
    end

    assert_redirected_to memory_path(@memory)
    assert Like.exists?(user: @user, memory: @memory)
  end

  test "共感を解除できる" do
    Like.create!(user: @user, memory: @memory)
    login_as(@user)

    assert_difference("Like.count", -1) do
      delete memory_like_path(@memory)
    end

    assert_redirected_to memory_path(@memory)
    assert_not Like.exists?(user: @user, memory: @memory)
  end

  test "同じ投稿に重複して共感できない" do
    login_as(@user)

    post memory_like_path(@memory)

    assert_no_difference("Like.count") do
      post memory_like_path(@memory)
    end
  end

  test "未ログインユーザーは共感を登録できない" do
    assert_no_difference("Like.count") do
      post memory_like_path(@memory)
    end

    assert_redirected_to login_path
  end

  test "未ログインユーザーは共感を解除できない" do
    Like.create!(user: @user, memory: @memory)

    assert_no_difference("Like.count") do
      delete memory_like_path(@memory)
    end

    assert_redirected_to login_path
  end

  test "他人の共感は解除できない" do
    Like.create!(user: @other_user, memory: @memory)
    login_as(@user)

    assert_no_difference("Like.count") do
      delete memory_like_path(@memory)
    end

    assert Like.exists?(user: @other_user, memory: @memory)
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
