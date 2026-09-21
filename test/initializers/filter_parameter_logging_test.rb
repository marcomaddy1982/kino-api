require "test_helper"

class FilterParameterLoggingTest < ActiveSupport::TestCase
  def filter(params)
    ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(params)
  end

  test "a user's phone number and name are filtered, at the top level and when wrapped" do
    filtered = filter(
      "name" => "Test User",
      "phone_number" => "+391234567890",
      "session" => { "name" => "Test User", "phone_number" => "+391234567890" }
    )

    assert_equal "[FILTERED]", filtered["name"]
    assert_equal "[FILTERED]", filtered["phone_number"]
    assert_equal "[FILTERED]", filtered["session"]["name"]
    assert_equal "[FILTERED]", filtered["session"]["phone_number"]
  end

  test "keys that merely contain the word name are not hidden" do
    filtered = filter("filename" => "a.png", "list" => { "rename" => "x" }, "tmdb_movie_id" => "550")

    assert_equal "a.png", filtered["filename"]
    assert_equal "x", filtered["list"]["rename"]
    assert_equal "550", filtered["tmdb_movie_id"]
  end

  test "the existing filters still apply" do
    filtered = filter("email" => "a@b.c", "password" => "Password1", "token" => "t")

    assert_equal [ "[FILTERED]" ], filtered.values.uniq
  end
end

class RegisterLoggingTest < ActionDispatch::IntegrationTest
  teardown do
    User.find_by(email: "new@example.com")&.destroy
  end

  test "a register request does not put the phone number, name or email in the logged params" do
    logged = +""
    subscriber = ActiveSupport::Notifications.subscribe("start_processing.action_controller") do |*, payload|
      logged << payload[:params].inspect
    end

    post "/v1/auth/register",
         params: { email: "new@example.com", password: "Password1", name: "Secret Name", phone_number: "+390000000001" },
         as: :json

    assert_response :created
    assert_not_includes logged, "Secret Name"
    assert_not_includes logged, "+390000000001"
    assert_not_includes logged, "new@example.com"
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end
