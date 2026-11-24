FactoryBot.define do
  factory :memory do
    title { "テスト用の思い出" }
    body { "これはテスト用の思い出です。この音楽を聴くと、当時の思い出がよみがえります。" }
    association :user

    songs do
      [
        association(
          :song,
          spotify_id: SecureRandom.alphanumeric(22)
        )
      ]
    end
  end
end
