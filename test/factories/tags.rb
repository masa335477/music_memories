FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "ロック#{n}" }
  end
end
