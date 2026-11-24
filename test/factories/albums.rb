FactoryBot.define do
  factory :album do
    spotify_id { SecureRandom.alphanumeric(22) }
    name { "テストアルバム" }
    artist_name { "テストアーティスト" }
    release_date { "2026-01-01" }
    image_url { nil }
    spotify_url { "https://open.spotify.com/album/#{spotify_id}" }
  end
end
