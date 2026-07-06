class User < ApplicationRecord
  has_many :lists, dependent: :destroy
  has_many :refresh_tokens, dependent: :destroy

  has_secure_password

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :phone_number, presence: true
  validates :password, length: { minimum: 8 },
                       format: { with: /\A(?=.*[A-Z])(?=.*\d).+\z/, message: "must contain at least one uppercase letter and one number" },
                       if: :password_digest_changed?
end
