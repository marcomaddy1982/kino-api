require "test_helper"

class TmdbMovieServiceTest < ActiveSupport::TestCase
  test "discover requests /discover/movie with page and sort" do
    stub = stub_tmdb("discover/movie", query: { "page" => "2", "sort_by" => "popularity.desc" })
    TmdbMovieService.discover(page: 2, sort_by: "popularity.desc")
    assert_requested stub
  end

  test "discover falls back to the default sort for an unknown value" do
    stub = stub_tmdb("discover/movie", query: { "sort_by" => "primary_release_date.desc" })
    TmdbMovieService.discover(sort_by: "bogus")
    assert_requested stub
  end

  test "discover clamps the page to TMDB's maximum" do
    stub = stub_tmdb("discover/movie", query: { "page" => "500" })
    TmdbMovieService.discover(page: 9999)
    assert_requested stub
  end

  test "search requests /search/movie with the query" do
    stub = stub_tmdb("search/movie", query: { "query" => "dune", "page" => "1" })
    TmdbMovieService.search(query: "dune", page: 1)
    assert_requested stub
  end

  test "search raises BadRequestError for a blank query" do
    assert_raises(KinoErrors::BadRequestError) { TmdbMovieService.search(query: "   ") }
  end

  test "fetch_movie raises NotFoundError only for a true 404" do
    stub_tmdb("movie/999", status: 404, body: { status_code: 34 })
    assert_raises(KinoErrors::NotFoundError) { TmdbMovieService.fetch_movie(999) }
  end

  test "fetch_movie raises UpstreamError when TMDB is unreachable" do
    stub_request(:get, "#{ENV["TMDB_API_BASE_URL"]}/movie/550").to_timeout
    assert_raises(KinoErrors::UpstreamError) { TmdbMovieService.fetch_movie(550) }
  end

  test "fetch_movie raises UpstreamError when TMDB responds with a 5xx status" do
    stub_tmdb("movie/550", status: 503, body: {})
    assert_raises(KinoErrors::UpstreamError) { TmdbMovieService.fetch_movie(550) }
  end

  test "fetch_movie raises UpstreamError when TMDB rate-limits (429)" do
    stub_tmdb("movie/550", status: 429, body: {})
    assert_raises(KinoErrors::UpstreamError) { TmdbMovieService.fetch_movie(550) }
  end

  test "fetch_movie raises UpstreamError when our TMDB credentials are rejected (401, 403)" do
    [ 401, 403 ].each do |status|
      stub_tmdb("movie/550", status: status, body: {})

      error = assert_raises(KinoErrors::UpstreamError) { TmdbMovieService.fetch_movie(550) }
      assert_equal status, error.upstream_status
    end
  end

  test "fetch_movie raises BadRequestError, not UpstreamError, when TMDB rejects the input (400, 422)" do
    [ 400, 422 ].each do |status|
      stub_tmdb("movie/550", status: status, body: {})

      error = assert_raises(KinoErrors::BadRequestError) { TmdbMovieService.fetch_movie(550) }
      assert_equal "TMDB rejected the request (#{status})", error.message
    end
  end

  test "fetch_movie raises UpstreamError on a malformed response body" do
    stub_request(:get, "#{ENV["TMDB_API_BASE_URL"]}/movie/550")
      .with(headers: { "Authorization" => "Bearer #{ENV["TMDB_ACCESS_TOKEN"]}" })
      .to_return(status: 200, body: "not json", headers: { "Content-Type" => "application/json" })

    assert_raises(KinoErrors::UpstreamError) { TmdbMovieService.fetch_movie(550) }
  end

  test "logs the exception class and a backtrace line on a TMDB failure" do
    stub_request(:get, "#{ENV["TMDB_API_BASE_URL"]}/movie/550").to_timeout

    Rails.logger.expects(:error).with { |msg| msg.include?("Faraday::") && msg.include?("tmdb_movie_service.rb") }

    assert_raises(KinoErrors::UpstreamError) { TmdbMovieService.fetch_movie(550) }
  end

  test "a non-success response raises UpstreamError carrying its status and a fixed message" do
    stub_tmdb("movie/550", status: 401, body: {})

    error = assert_raises(KinoErrors::UpstreamError) { TmdbMovieService.fetch_movie(550) }

    assert_equal 401, error.upstream_status
    assert_equal "TMDB responded 401", error.message
  end

  test "a connection failure raises UpstreamError with the underlying error as its cause and no status" do
    stub_request(:get, "#{ENV["TMDB_API_BASE_URL"]}/movie/550").to_timeout

    error = assert_raises(KinoErrors::UpstreamError) { TmdbMovieService.fetch_movie(550) }

    assert_nil error.upstream_status
    assert_equal "TMDB request failed", error.message
    assert_kind_of Faraday::Error, error.cause
  end

  test "does not report to Sentry itself, so the handler reports each failure once" do
    stub_request(:get, "#{ENV["TMDB_API_BASE_URL"]}/movie/550").to_timeout
    Sentry.expects(:capture_exception).never

    assert_raises(KinoErrors::UpstreamError) { TmdbMovieService.fetch_movie(550) }
  end
end
