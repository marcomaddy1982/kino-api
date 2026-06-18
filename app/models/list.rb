class List < ApplicationRecord
  belongs_to :user
  has_many :list_items, dependent: :destroy

  validates :name, presence: true
  validates :is_favourite, uniqueness: { scope: :user_id, message: "list already exists" }, if: :is_favourite?
end
