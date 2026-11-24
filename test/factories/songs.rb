FactoryBot.define do
  factory :song do
    spotify_id { SecureRandom.alphanumeric(22) }
    name { "テスト楽曲" }
    artist_name { "テストアーティスト" }
    album_name { "テストアルバム" }
    image_url { nil }
    spotify_url { "https://open.spotify.com/track/#{spotify_id}" }
  end
end
