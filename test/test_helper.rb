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
    def auth_header(user:)
      { "Authorization" => "Bearer #{JwtService.encode(user.id)}" }
    end

    def stub_tmdb_movie(tmdb_movie_id:, title: "Test Movie", poster_path: "/test.jpg", vote_average: 7.0, release_date: "2020-01-01")
      stub_request(:get, "#{ENV["TMDB_API_BASE_URL"]}/movie/#{tmdb_movie_id}")
        .with(headers: { "Authorization" => "Bearer #{ENV["TMDB_ACCESS_TOKEN"]}" })
        .to_return(
          status: 200,
          body: { id: tmdb_movie_id, title:, poster_path:, vote_average:, release_date: }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end
  end
end
