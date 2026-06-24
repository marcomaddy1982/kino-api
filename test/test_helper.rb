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

    def stub_tmdb_movie(tmdb_movie_id:, title: "Test Movie", poster_path: "/test.jpg", vote_average: 7.0, release_date: "2020-01-01")
      stub_request(:get, "#{ENV["TMDB_API_BASE_URL"]}/movie/#{tmdb_movie_id}")
        .with(headers: { "Authorization" => "Bearer #{ENV["TMDB_ACCESS_TOKEN"]}" })
        .to_return(
          status: 200,
          body: { id: tmdb_movie_id, title: title, poster_path: poster_path, vote_average: vote_average, release_date: release_date }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    def stub_tmdb_account(session_id: "fake-session-id", account_id: 123)
      stub_request(:get, "#{ENV["TMDB_API_BASE_URL"]}/account")
        .with(
          query: hash_including("session_id" => session_id),
          headers: { "Authorization" => "Bearer #{ENV["TMDB_ACCESS_TOKEN"]}" }
        )
        .to_return(
          status: 200,
          body: { id: account_id }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end
  end
end
