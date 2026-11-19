FactoryBot.define do
  factory :memory_tag do
    association :memory
    association :tag
  end
end
