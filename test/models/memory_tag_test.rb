require "test_helper"

class MemoryTagTest < ActiveSupport::TestCase
  test "投稿とタグを関連付けられる" do
    memory_tag = build(:memory_tag)

    assert memory_tag.valid?
  end

  test "同じ投稿に同じタグを重複登録できない" do
    memory = create(:memory)
    tag = create(:tag)

    create(:memory_tag, memory: memory, tag: tag)
    duplicate = build(:memory_tag, memory: memory, tag: tag)

    assert_not duplicate.valid?
    assert duplicate.errors[:tag_id].any?
  end

  test "同じタグを別の投稿にも登録できる" do
    tag = create(:tag)
    memory1 = create(:memory)
    memory2 = create(:memory)

    first = create(:memory_tag, memory: memory1, tag: tag)
    second = build(:memory_tag, memory: memory2, tag: tag)

    assert first.persisted?
    assert second.valid?
  end

  test "投稿を削除すると関連するMemoryTagも削除される" do
    memory = create(:memory)
    tag = create(:tag)

    create(:memory_tag, memory: memory, tag: tag)

    assert_difference "MemoryTag.count", -1 do
      memory.destroy!
    end
  end
end
