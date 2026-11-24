require "test_helper"

class ListeningInterestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = FactoryBot.create(:user)
    @other_user = FactoryBot.create(:user)
    @memory = FactoryBot.create(:memory, user: @user)
  end

  test "ログイン中のユーザーは聴いてみたいを登録できる" do
    login_as(@user)

    assert_difference("ListeningInterest.count", 1) do
      post memory_listening_interest_path(@memory)
    end

    assert_redirected_to memory_path(@memory)
    assert ListeningInterest.exists?(user: @user, memory: @memory)
  end

  test "聴いてみたいを解除できる" do
    ListeningInterest.create!(user: @user, memory: @memory)
    login_as(@user)

    assert_difference("ListeningInterest.count", -1) do
      delete memory_listening_interest_path(@memory)
    end

    assert_redirected_to memory_path(@memory)
    assert_not ListeningInterest.exists?(user: @user, memory: @memory)
  end

  test "同じ投稿に重複して聴いてみたいを登録できない" do
    login_as(@user)

    post memory_listening_interest_path(@memory)

    assert_no_difference("ListeningInterest.count") do
      post memory_listening_interest_path(@memory)
    end
  end

  test "未ログインユーザーは聴いてみたいを登録できない" do
    assert_no_difference("ListeningInterest.count") do
      post memory_listening_interest_path(@memory)
    end

    assert_redirected_to login_path
  end

  test "未ログインユーザーは聴いてみたいを解除できない" do
    ListeningInterest.create!(user: @user, memory: @memory)

    assert_no_difference("ListeningInterest.count") do
      delete memory_listening_interest_path(@memory)
    end

    assert_redirected_to login_path
  end

  test "他人の聴いてみたいは解除できない" do
    ListeningInterest.create!(user: @other_user, memory: @memory)
    login_as(@user)

    assert_no_difference("ListeningInterest.count") do
      delete memory_listening_interest_path(@memory)
    end

    assert ListeningInterest.exists?(user: @other_user, memory: @memory)
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
