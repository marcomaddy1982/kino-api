require "test_helper"

class AuthServiceTest < ActiveSupport::TestCase
  EMAIL = "auth-service@example.com"

  def valid_attributes
    { email: EMAIL, password: "Password1", name: "Auth User", phone_number: "+391234567890" }
  end

  teardown { User.find_by(email: EMAIL)&.destroy }

  # register
  test "register creates a user and issues tokens" do
    result = AuthService.register(**valid_attributes)

    assert result[:user].persisted?
    assert result[:access_token].present?
    assert result[:refresh_token].present?
  end

  test "register stores only the refresh token's digest, never the raw value" do
    result = AuthService.register(**valid_attributes)

    record = result[:user].refresh_tokens.last
    assert_equal Digest::SHA256.hexdigest(result[:refresh_token]), record.token_digest
  end

  test "register raises BadRequestError and creates nothing for invalid attributes" do
    assert_raises(KinoErrors::BadRequestError) { AuthService.register(**valid_attributes.merge(password: "short")) }
    assert_nil User.find_by(email: EMAIL)
  end

  # login
  test "login returns tokens for correct credentials" do
    user = User.create!(valid_attributes)
    result = AuthService.login(email: EMAIL, password: "Password1")
    assert_equal user.id, result[:user].id
  end

  test "login is case-insensitive and trims whitespace on email" do
    user = User.create!(valid_attributes)
    result = AuthService.login(email: "  #{EMAIL.upcase}  ", password: "Password1")
    assert_equal user.id, result[:user].id
  end

  test "login raises AuthenticationError for the wrong password" do
    User.create!(valid_attributes)
    assert_raises(KinoErrors::AuthenticationError) { AuthService.login(email: EMAIL, password: "WrongPass1") }
  end

  test "login raises AuthenticationError for an unknown email" do
    assert_raises(KinoErrors::AuthenticationError) { AuthService.login(email: "nobody@example.com", password: "Password1") }
  end

  # logout
  test "logout revokes the matching refresh token" do
    User.create!(valid_attributes)
    tokens = AuthService.login(email: EMAIL, password: "Password1")

    AuthService.logout(raw_token: tokens[:refresh_token])

    record = RefreshToken.find_by(token_digest: Digest::SHA256.hexdigest(tokens[:refresh_token]))
    assert record.revoked_at.present?
  end

  test "logout does not raise for an unknown token" do
    AuthService.logout(raw_token: "unknown-token")
    assert true
  end

  # refresh
  test "refresh rotates the token: old is revoked, a new raw token is issued" do
    User.create!(valid_attributes)
    tokens = AuthService.login(email: EMAIL, password: "Password1")

    rotated = AuthService.refresh(raw_token: tokens[:refresh_token])

    old_record = RefreshToken.find_by(token_digest: Digest::SHA256.hexdigest(tokens[:refresh_token]))
    assert old_record.revoked_at.present?
    assert_not_equal tokens[:refresh_token], rotated[:refresh_token]
  end

  test "refresh raises AuthenticationError when the same token is used twice (replay)" do
    User.create!(valid_attributes)
    tokens = AuthService.login(email: EMAIL, password: "Password1")
    AuthService.refresh(raw_token: tokens[:refresh_token])

    assert_raises(KinoErrors::AuthenticationError) { AuthService.refresh(raw_token: tokens[:refresh_token]) }
  end

  test "refresh raises AuthenticationError for an expired token" do
    User.create!(valid_attributes)
    tokens = AuthService.login(email: EMAIL, password: "Password1")
    RefreshToken.find_by(token_digest: Digest::SHA256.hexdigest(tokens[:refresh_token]))
      .update!(expires_at: 1.minute.ago)

    assert_raises(KinoErrors::AuthenticationError) { AuthService.refresh(raw_token: tokens[:refresh_token]) }
  end

  test "refresh raises AuthenticationError for an unknown token" do
    assert_raises(KinoErrors::AuthenticationError) { AuthService.refresh(raw_token: "unknown-token") }
  end
end
