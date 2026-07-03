class JwtService
  ALGORITHM = "HS256"
  ACCESS_TOKEN_TTL = 30.minutes

  class << self
    def encode(user_id)
      payload = {
        sub: user_id,
        iat: Time.current.to_i,
        exp: ACCESS_TOKEN_TTL.from_now.to_i
      }
      JWT.encode(payload, secret, ALGORITHM)
    end

    def decode(token)
      payload = JWT.decode(token, secret, true, algorithm: ALGORITHM).first
      payload.with_indifferent_access
    rescue JWT::DecodeError
      raise KinoErrors::AuthenticationError
    end

    private

    def secret
      Rails.application.secret_key_base
    end
  end
end
