
require "test_helper"
require "minitest/mock"

class Memories::SaveServiceTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    @song = FactoryBot.create(:song)
  end

  test "楽曲付きの投稿を作成できる" do
    memory = @user.memories.build(
      title: "好きな楽曲",
      body: "何度も聴きたくなる楽曲です",
      spotify_track_id: @song.spotify_id
    )

    service = Memories::SaveService.new(memory: memory)

    assert service.create
    assert memory.persisted?
    assert_equal [ @song ], memory.songs.to_a
    assert_equal @song, service.selected_music
  end

  test "タイトルが空の場合は投稿を保存しない" do
    memory = @user.memories.build(
      title: "",
      body: "本文",
      spotify_track_id: @song.spotify_id
    )

    service = Memories::SaveService.new(memory: memory)

    assert_not service.create
    assert_not memory.persisted?
    assert_includes memory.errors.attribute_names, :title
  end

  test "不正な新規タグ名の場合は投稿を保存しない" do
    memory = @user.memories.build(
      title: "テスト投稿",
      body: "本文",
      spotify_track_id: @song.spotify_id,
      new_tag_name: "あ" * 31
    )

    service = Memories::SaveService.new(memory: memory)

    assert_no_difference [ "Memory.count", "Tag.count", "MemoryTag.count" ] do
      assert_not service.create
    end

    assert_not memory.persisted?
    assert memory.errors[:base].any?
  end

  test "投稿のタイトルと本文を更新できる" do
    memory = @user.memories.create!(
      title: "変更前",
      body: "変更前の本文",
      songs: [ @song ]
    )

    service = Memories::SaveService.new(memory: memory)

    assert service.update(
      title: "変更後",
      body: "変更後の本文"
    )

    memory.reload
    assert_equal "変更後", memory.title
    assert_equal "変更後の本文", memory.body
  end

  test "更新に失敗した場合は以前の内容を維持する" do
    memory = @user.memories.create!(
      title: "変更前",
      body: "変更前の本文",
      songs: [ @song ]
    )

    service = Memories::SaveService.new(memory: memory)

    assert_not service.update(
      title: "",
      body: "変更後の本文"
    )

    memory.reload
    assert_equal "変更前", memory.title
    assert_equal "変更前の本文", memory.body
  end
end
