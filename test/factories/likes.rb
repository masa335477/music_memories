FactoryBot.define do
  factory :like do
    association :user
    association :memory
  end
end
