class User < ApplicationRecord
  has_many :lists, dependent: :destroy

  validates :tmdb_account_id, presence: true, uniqueness: true
end
