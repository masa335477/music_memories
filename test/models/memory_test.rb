require "test_helper"

class MemoryTest < ActiveSupport::TestCase
  test "FactoryBotでMemoryを作成できる" do
    memory = build(:memory)

    assert_equal "テスト用の思い出", memory.title
    assert memory.valid?
  end

  test "Fakerでテストデータを生成できる" do
    title = Faker::Lorem.sentence

    assert title.is_a?(String)
    assert_not title.empty?
  end

  test "Shoulda Matchersでtitleカラムを確認できる" do
    matcher = have_db_column(:title).of_type(:string)

    assert matcher.matches?(Memory.new), matcher.failure_message
  end
end
