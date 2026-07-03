class User < ApplicationRecord
  has_many :lists, dependent: :destroy
  has_many :refresh_tokens, dependent: :destroy

  has_secure_password

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
end
