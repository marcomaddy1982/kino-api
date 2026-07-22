require "test_helper"

class V1::Auth::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "existing@example.com", password: "Password1", name: "Existing User", phone_number: "+391234567890")
  end

  teardown do
    @user.destroy
  end

  # POST /v1/auth/register
  test "register returns 201 with tokens and user" do
    post v1_auth_register_path, params: { email: "new@example.com", password: "Password1", name: "New User", phone_number: "+390987654321" }, as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert body["accessToken"].present?
    assert body["refreshToken"].present?
    assert_equal "new@example.com", body["user"]["email"]
    assert_equal "New User", body["user"]["name"]
    assert_equal "+390987654321", body["user"]["phoneNumber"]
  ensure
    User.find_by(email: "new@example.com")&.destroy
  end

  test "register returns 400 on missing required field" do
    post v1_auth_register_path, params: { email: "new@example.com", password: "Password1", phone_number: "+391234567890" }, as: :json
    assert_response :bad_request
  end

  test "register returns 400 on duplicate email" do
    post v1_auth_register_path, params: { email: "existing@example.com", password: "Password1", name: "Another", phone_number: "+391234567890" }, as: :json
    assert_response :bad_request
  end

  test "register returns 400 on password too short" do
    post v1_auth_register_path, params: { email: "new@example.com", password: "Pass1", name: "New User", phone_number: "+390987654321" }, as: :json
    assert_response :bad_request
  ensure
    User.find_by(email: "new@example.com")&.destroy
  end

  test "register returns 400 on password without uppercase" do
    post v1_auth_register_path, params: { email: "new@example.com", password: "password1", name: "New User", phone_number: "+390987654321" }, as: :json
    assert_response :bad_request
  ensure
    User.find_by(email: "new@example.com")&.destroy
  end

  test "register returns 400 on password without number" do
    post v1_auth_register_path, params: { email: "new@example.com", password: "Password", name: "New User", phone_number: "+390987654321" }, as: :json
    assert_response :bad_request
  ensure
    User.find_by(email: "new@example.com")&.destroy
  end

  # POST /v1/auth/login
  test "login returns 200 with tokens and user" do
    post v1_auth_login_path, params: { email: "existing@example.com", password: "Password1" }, as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert body["accessToken"].present?
    assert body["refreshToken"].present?
    assert_equal "existing@example.com", body["user"]["email"]
  end

  test "login returns 401 on wrong password" do
    post v1_auth_login_path, params: { email: "existing@example.com", password: "wrongpassword" }, as: :json
    assert_response :unauthorized
  end

  test "login returns 401 on unknown email" do
    post v1_auth_login_path, params: { email: "nobody@example.com", password: "Password1" }, as: :json
    assert_response :unauthorized
  end

  test "login does not accept params wrapped under a session key" do
    post v1_auth_login_path, params: { session: { email: "existing@example.com", password: "Password1" } }, as: :json
    assert_response :bad_request
  end

  # POST /v1/auth/refresh
  test "refresh returns 200 with new tokens" do
    result = AuthService.login(email: "existing@example.com", password: "Password1")

    post v1_auth_refresh_path, params: { refresh_token: result[:refresh_token] }, as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert body["accessToken"].present?
    assert body["refreshToken"].present?
  end

  test "refresh rotates the token — old token is rejected" do
    result = AuthService.login(email: "existing@example.com", password: "Password1")
    old_token = result[:refresh_token]

    post v1_auth_refresh_path, params: { refresh_token: old_token }, as: :json
    assert_response :ok

    post v1_auth_refresh_path, params: { refresh_token: old_token }, as: :json
    assert_response :unauthorized
  end

  test "refresh returns 401 on invalid token" do
    post v1_auth_refresh_path, params: { refresh_token: "not-a-valid-token" }, as: :json
    assert_response :unauthorized
  end

  test "refresh returns 401 on revoked token" do
    result = AuthService.login(email: "existing@example.com", password: "Password1")
    AuthService.logout(raw_token: result[:refresh_token])

    post v1_auth_refresh_path, params: { refresh_token: result[:refresh_token] }, as: :json
    assert_response :unauthorized
  end

  # DELETE /v1/auth/logout
  test "logout returns 204" do
    result = AuthService.login(email: "existing@example.com", password: "Password1")
    delete v1_auth_logout_path, params: { refresh_token: result[:refresh_token] }, as: :json
    assert_response :no_content
  end

  test "logout invalidates the refresh token" do
    result = AuthService.login(email: "existing@example.com", password: "Password1")
    delete v1_auth_logout_path, params: { refresh_token: result[:refresh_token] }, as: :json

    post v1_auth_refresh_path, params: { refresh_token: result[:refresh_token] }, as: :json
    assert_response :unauthorized
  end

  test "logout is idempotent — returns 204 even with invalid token" do
    delete v1_auth_logout_path, params: { refresh_token: "nonexistent-token" }, as: :json
    assert_response :no_content
  end
end
