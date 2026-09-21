class AuthService
  class << self
    def register(email:, password:, name:, phone_number:)
      user = User.new(email: email, password: password, name: name, phone_number: phone_number)
      # The client only sees a generic 400; the reason (email taken, weak
      # password...) is kept for the log. Validation messages hold no values.
      raise KinoErrors::BadRequestError, user.errors.full_messages.to_sentence unless user.save
      issue_tokens(user)
    end

    def login(email:, password:)
      user = User.find_by(email: email.downcase.strip)
      raise KinoErrors::AuthenticationError unless user&.authenticate(password)
      issue_tokens(user)
    end

    def logout(raw_token:)
      digest = Digest::SHA256.hexdigest(raw_token)
      RefreshToken.find_by(token_digest: digest)&.update!(revoked_at: Time.current)
    end

    def refresh(raw_token:)
      digest = Digest::SHA256.hexdigest(raw_token)
      token_record = RefreshToken.active.find_by(token_digest: digest)
      raise KinoErrors::AuthenticationError unless token_record

      token_record.update!(revoked_at: Time.current)
      issue_tokens(token_record.user)
    end

    private

    def issue_tokens(user)
      raw_token = SecureRandom.hex(32)
      user.refresh_tokens.create!(
        token_digest: Digest::SHA256.hexdigest(raw_token),
        expires_at: 30.days.from_now
      )
      {
        access_token: JwtService.encode(user.id),
        refresh_token: raw_token,
        user: user
      }
    end
  end
end
