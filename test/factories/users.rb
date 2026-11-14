FactoryBot.define do
  factory :user do
    name { "テストユーザー" }
    email { "factory-#{SecureRandom.uuid}@example.com" }
    password { "password123" }
  end
end
