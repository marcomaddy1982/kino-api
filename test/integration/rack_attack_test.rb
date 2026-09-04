require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
  end

  teardown do
    Rack::Attack.enabled = false
  end

  test "throttles repeated login attempts for the same email" do
    6.times { post "/v1/auth/login", params: { email: "x@example.com", password: "wrong" }, as: :json }

    assert_response :too_many_requests
    assert_equal "Too many requests", JSON.parse(response.body)["error"]
  end

  test "throttles registration spam from the same IP" do
    6.times do |i|
      post "/v1/auth/register",
        params: { email: "spam#{i}@example.com", password: "Password1", name: "Spam", phone_number: "+391234567890" },
        as: :json
    end

    assert_response :too_many_requests
  end
end
