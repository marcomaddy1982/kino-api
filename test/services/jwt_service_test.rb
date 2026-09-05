require "test_helper"

class JwtServiceTest < ActiveSupport::TestCase
  test "encode produces a token decodable back to the same user id" do
    token = JwtService.encode(42)
    payload = JwtService.decode(token)
    assert_equal 42, payload[:sub]
  end

  test "decode supports indifferent access on the payload" do
    token = JwtService.encode(7)
    payload = JwtService.decode(token)
    assert_equal 7, payload["sub"]
    assert_equal 7, payload[:sub]
  end

  test "decode raises AuthenticationError for a tampered signature" do
    token = JwtService.encode(1)
    tampered = token.sub(/\.[^.]+\z/, ".tampered-signature")
    assert_raises(KinoErrors::AuthenticationError) { JwtService.decode(tampered) }
  end

  test "decode raises AuthenticationError for an expired token" do
    token = travel_to(31.minutes.ago) { JwtService.encode(1) }
    assert_raises(KinoErrors::AuthenticationError) { JwtService.decode(token) }
  end

  test "decode raises AuthenticationError for garbage input" do
    assert_raises(KinoErrors::AuthenticationError) { JwtService.decode("not-a-jwt") }
  end

  test "decode rejects a token forged with the 'none' algorithm" do
    forged = JWT.encode({ sub: 1, exp: 1.hour.from_now.to_i }, nil, "none")
    assert_raises(KinoErrors::AuthenticationError) { JwtService.decode(forged) }
  end
end
