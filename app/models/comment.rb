class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :memory

  validates :body, presence: { message: "を入力してください" }, length: { maximum: 1000, message: "は1000文字以内で入力してください" }
end
