class Tag < ApplicationRecord
  has_many :memory_tags, dependent: :destroy
  has_many :memories, through: :memory_tags

  validates :name, presence: true,
                   uniqueness: true,
                   length: { maximum: 30, message: "は30文字以内で入力してください" }

  before_validation :normalize_name

  private

  def normalize_name
    self.name = name.strip if name.present?
  end
end
