require "test_helper"

class V1::MoviesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "user@example.com", password: "Password1", name: "Test User", phone_number: "+391234567890")
    @headers = auth_header(user: @user)
  end

  teardown do
    @user.destroy
  end

  # GET /v1/movies
  test "index returns discover results" do
    stub_tmdb("discover/movie", body: { page: 1, results: [ { id: 1, title: "A" } ], total_pages: 1, total_results: 1 })
    get v1_movies_path, headers: @headers, as: :json

    assert_response :ok
    assert_equal "A", JSON.parse(response.body).dig("results", 0, "title")
  end

  test "index forwards page and sort_by to TMDB" do
    stub = stub_tmdb("discover/movie", query: { "page" => "3", "sort_by" => "popularity.desc" })
    get v1_movies_path(page: 3, sort_by: "popularity.desc"), headers: @headers, as: :json

    assert_response :ok
    assert_requested stub
  end

  test "index returns 401 without auth" do
    get v1_movies_path, as: :json
    assert_response :unauthorized
  end

  # GET /v1/movies/search
  test "search returns results for a query" do
    stub_tmdb("search/movie", query: { "query" => "dune" },
      body: { page: 1, results: [ { id: 2, title: "Dune" } ], total_pages: 1, total_results: 1 })
    get search_v1_movies_path(query: "dune"), headers: @headers, as: :json

    assert_response :ok
    assert_equal "Dune", JSON.parse(response.body).dig("results", 0, "title")
  end

  test "search returns the Kino error body when query is missing" do
    get search_v1_movies_path, headers: @headers, as: :json

    assert_response :bad_request
    assert_equal({ "error" => "Bad request" }, JSON.parse(response.body))
  end

  # GET /v1/movies/:id
  test "show returns movie details" do
    stub_tmdb_movie(tmdb_movie_id: 550, title: "Fight Club")
    get v1_movie_path(550), headers: @headers, as: :json

    assert_response :ok
    assert_equal "Fight Club", JSON.parse(response.body)["title"]
  end

  test "show includes the user's favourite and calendar state" do
    stub_tmdb_movie(tmdb_movie_id: 550, title: "Fight Club")
    ListService.find_or_create_favourites(@user).list_items.create!(tmdb_movie_id: 550)
    entry = @user.calendar_entries.create!(tmdb_movie_id: 550, scheduled_on: "2026-09-17", title: "Fight Club")

    get v1_movie_path(550), headers: @headers, as: :json

    assert_response :ok
    assert_equal(
      { "is_favourite" => true,
        "calendar_entries" => [ { "id" => entry.id, "scheduled_on" => "2026-09-17", "watched" => false } ] },
      JSON.parse(response.body)["user"]
    )
  end

  test "show returns user state with no favourite and no entries by default" do
    stub_tmdb_movie(tmdb_movie_id: 550, title: "Fight Club")

    get v1_movie_path(550), headers: @headers, as: :json

    assert_equal({ "is_favourite" => false, "calendar_entries" => [] }, JSON.parse(response.body)["user"])
  end

  test "show still returns the movie with user null when the user state fails" do
    stub_tmdb_movie(tmdb_movie_id: 550, title: "Fight Club")

    MovieUserStateService.expects(:for).raises(ActiveRecord::StatementInvalid, "boom")

    get v1_movie_path(550), headers: @headers, as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal "Fight Club", body["title"]
    assert body.key?("user")
    assert_nil body["user"]
  end

  test "show returns 404 when TMDB has no such movie" do
    stub_tmdb("movie/999", status: 404, body: { status_code: 34 })
    get v1_movie_path(999), headers: @headers, as: :json

    assert_response :not_found
  end

  test "show returns 502 with the Kino error body when TMDB is unreachable" do
    stub_request(:get, "#{ENV["TMDB_API_BASE_URL"]}/movie/550").to_timeout

    get v1_movie_path(550), headers: @headers, as: :json

    assert_response :bad_gateway
    assert_equal({ "error" => "Upstream service unavailable" }, JSON.parse(response.body))
  end

  test "show returns 502, not 404, when TMDB responds with a 5xx status" do
    stub_tmdb("movie/550", status: 503, body: {})

    get v1_movie_path(550), headers: @headers, as: :json

    assert_response :bad_gateway
  end
end
