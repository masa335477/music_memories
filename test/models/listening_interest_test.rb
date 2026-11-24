require "test_helper"

class ListeningInterestTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    @memory = FactoryBot.create(:memory, user: @user)
  end

  test "聴いてみたいを登録できる" do
    interest = ListeningInterest.new(user: @user, memory: @memory)

    assert interest.valid?
  end

  test "同じユーザーは同じ投稿に重複登録できない" do
    ListeningInterest.create!(user: @user, memory: @memory)

    duplicate = ListeningInterest.new(user: @user, memory: @memory)

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :user_id
  end

  test "異なるユーザーは同じ投稿に登録できる" do
    other_user = FactoryBot.create(:user)
    ListeningInterest.create!(user: @user, memory: @memory)

    interest = ListeningInterest.new(user: other_user, memory: @memory)

    assert interest.valid?
  end

  test "同じユーザーは異なる投稿に登録できる" do
    other_memory = FactoryBot.create(:memory, user: @user)
    ListeningInterest.create!(user: @user, memory: @memory)

    interest = ListeningInterest.new(user: @user, memory: other_memory)

    assert interest.valid?
  end
end
