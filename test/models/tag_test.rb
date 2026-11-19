require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "タグ名があれば登録できる" do
    tag = build(:tag, name: "ロック")

    assert tag.valid?
  end

  test "タグ名が空の場合は登録できない" do
    tag = build(:tag, name: "")

    assert_not tag.valid?
    assert tag.errors[:name].any?
  end

  test "タグ名がnilの場合は登録できない" do
    tag = build(:tag, name: nil)

    assert_not tag.valid?
    assert tag.errors[:name].any?
  end

  test "同じタグ名を重複登録できない" do
    create(:tag, name: "ロック")
    tag = build(:tag, name: "ロック")

    assert_not tag.valid?
    assert tag.errors[:name].any?
  end

  test "タグ名の前後の空白が除去される" do
    tag = create(:tag, name: " ロック ")

    assert_equal "ロック", tag.name
  end

  test "空白を除去した結果が同じタグ名なら登録できない" do
    create(:tag, name: "ロック")
    tag = build(:tag, name: " ロック ")

    assert_not tag.valid?
    assert tag.errors[:name].any?
  end

  test "タグ名が30文字以内なら登録できる" do
    tag = build(:tag, name: "あ" * 30)

    assert tag.valid?
  end

  test "タグ名が31文字以上なら登録できない" do
    tag = build(:tag, name: "あ" * 31)

    assert_not tag.valid?
    assert tag.errors[:name].any?
  end
end
