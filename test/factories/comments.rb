FactoryBot.define do
  factory :comment do
    association :user
    association :memory
    body { "音楽についての素敵な感想ですね！" }
  end
end
