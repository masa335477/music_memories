FactoryBot.define do
  factory :memory do
    title { "テスト用の思い出" }
    association :user
  end
end
