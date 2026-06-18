require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter "/test/"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"

WebMock.disable_net_connect!

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    def auth_header(session_id: "fake-session-id")
      stub_tmdb_account(session_id: session_id)
      { "Authorization" => "Bearer #{session_id}" }
    end

    def stub_tmdb_account(session_id: "fake-session-id", account_id: 123)
      stub_request(:get, "#{ENV["TMDB_API_BASE_URL"]}/3/account")
        .with(query: hash_including("session_id" => session_id))
        .to_return(
          status: 200,
          body: { id: account_id }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end
  end
end
