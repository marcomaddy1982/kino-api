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

  test "search returns 400 without a query" do
    get search_v1_movies_path, headers: @headers, as: :json
    assert_response :bad_request
  end

  # GET /v1/movies/:id
  test "show returns movie details" do
    stub_tmdb_movie(tmdb_movie_id: 550, title: "Fight Club")
    get v1_movie_path(550), headers: @headers, as: :json

    assert_response :ok
    assert_equal "Fight Club", JSON.parse(response.body)["title"]
  end

  test "show returns 404 when TMDB has no such movie" do
    stub_tmdb("movie/999", status: 404, body: { status_code: 34 })
    get v1_movie_path(999), headers: @headers, as: :json

    assert_response :not_found
  end
end
