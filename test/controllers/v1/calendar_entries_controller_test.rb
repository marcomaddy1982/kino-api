require "test_helper"

class V1::CalendarEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "calendar@example.com", password: "Password1", name: "Calendar User", phone_number: "+391234567890")
    @other_user = User.create!(email: "other@example.com", password: "Password1", name: "Other User", phone_number: "+390987654321")
    @headers = auth_header(user: @user)
    @tmdb_movie_id = 550
    stub_tmdb_movie(tmdb_movie_id: @tmdb_movie_id, title: "Fight Club", poster_path: "/fight_club.jpg", vote_average: 8.4, release_date: "1999-10-15")
  end

  teardown do
    @user.destroy
    @other_user.destroy
  end

  # GET /v1/calendar

  test "index returns 200 with entries grouped by date" do
    @user.calendar_entries.create!(tmdb_movie_id: @tmdb_movie_id, scheduled_on: "2026-07-10", title: "Fight Club", poster_path: "/fight_club.jpg", vote_average: 8.4, release_date: "1999-10-15")

    get "/v1/calendar", params: { month: "2026-07" }, headers: @headers

    assert_response :ok
    body = JSON.parse(response.body)
    assert body.key?("2026-07-10")
    assert_equal 1, body["2026-07-10"].length
    assert_equal "Fight Club", body["2026-07-10"].first["title"]
    assert_equal "/fight_club.jpg", body["2026-07-10"].first["posterPath"]
  end

  test "index returns only current user entries" do
    @user.calendar_entries.create!(tmdb_movie_id: @tmdb_movie_id, scheduled_on: "2026-07-10", title: "Fight Club", poster_path: "/fight_club.jpg", vote_average: 8.4, release_date: "1999-10-15")
    @other_user.calendar_entries.create!(tmdb_movie_id: 278, scheduled_on: "2026-07-10", title: "Shawshank", poster_path: "/shawshank.jpg", vote_average: 9.3, release_date: "1994-10-14")

    get "/v1/calendar", params: { month: "2026-07" }, headers: @headers

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 1, body["2026-07-10"].length
    assert_equal "Fight Club", body["2026-07-10"].first["title"]
  end

  test "index defaults to current month when no month param given" do
    get "/v1/calendar", headers: @headers
    assert_response :ok
  end

  test "index returns 400 on invalid month format" do
    get "/v1/calendar", params: { month: "9999-99" }, headers: @headers
    assert_response :bad_request
  end

  test "index returns 401 without auth token" do
    get "/v1/calendar"
    assert_response :unauthorized
  end

  # POST /v1/calendar/entries

  test "create returns 201 with entry and persists snapshot fields" do
    post "/v1/calendar/entries", params: { tmdb_movie_id: @tmdb_movie_id, scheduled_on: "2026-07-15" }, headers: @headers, as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Fight Club", body["title"]
    assert_equal "/fight_club.jpg", body["posterPath"]
    assert_equal false, body["watched"]
    assert_equal "2026-07-15", body["scheduledOn"]
  end

  test "create returns 400 on duplicate movie on same day" do
    @user.calendar_entries.create!(tmdb_movie_id: @tmdb_movie_id, scheduled_on: "2026-07-15", title: "Fight Club", poster_path: "/fight_club.jpg", vote_average: 8.4, release_date: "1999-10-15")

    post "/v1/calendar/entries", params: { tmdb_movie_id: @tmdb_movie_id, scheduled_on: "2026-07-15" }, headers: @headers, as: :json

    assert_response :bad_request
  end

  test "create returns 401 without auth token" do
    post "/v1/calendar/entries", params: { tmdb_movie_id: @tmdb_movie_id, scheduled_on: "2026-07-15" }, as: :json
    assert_response :unauthorized
  end

  # DELETE /v1/calendar/entries/:id

  test "destroy returns 204 and removes entry" do
    entry = @user.calendar_entries.create!(tmdb_movie_id: @tmdb_movie_id, scheduled_on: "2026-07-15", title: "Fight Club", poster_path: "/fight_club.jpg", vote_average: 8.4, release_date: "1999-10-15")

    delete "/v1/calendar/entries/#{entry.id}", headers: @headers

    assert_response :no_content
    assert_nil CalendarEntry.find_by(id: entry.id)
  end

  test "destroy returns 404 on another user's entry" do
    entry = @other_user.calendar_entries.create!(tmdb_movie_id: @tmdb_movie_id, scheduled_on: "2026-07-15", title: "Fight Club", poster_path: "/fight_club.jpg", vote_average: 8.4, release_date: "1999-10-15")

    delete "/v1/calendar/entries/#{entry.id}", headers: @headers

    assert_response :not_found
  end

  test "destroy returns 401 without auth token" do
    entry = @user.calendar_entries.create!(tmdb_movie_id: @tmdb_movie_id, scheduled_on: "2026-07-15", title: "Fight Club", poster_path: "/fight_club.jpg", vote_average: 8.4, release_date: "1999-10-15")

    delete "/v1/calendar/entries/#{entry.id}"

    assert_response :unauthorized
  end

  # PATCH /v1/calendar/entries/:id/toggle_watched

  test "toggle_watched flips watched from false to true" do
    entry = @user.calendar_entries.create!(tmdb_movie_id: @tmdb_movie_id, scheduled_on: "2026-07-15", title: "Fight Club", poster_path: "/fight_club.jpg", vote_average: 8.4, release_date: "1999-10-15")

    patch "/v1/calendar/entries/#{entry.id}/toggle_watched", headers: @headers

    assert_response :ok
    assert_equal true, JSON.parse(response.body)["watched"]
  end

  test "toggle_watched flips watched from true to false" do
    entry = @user.calendar_entries.create!(tmdb_movie_id: @tmdb_movie_id, scheduled_on: "2026-07-15", title: "Fight Club", poster_path: "/fight_club.jpg", vote_average: 8.4, release_date: "1999-10-15", watched: true)

    patch "/v1/calendar/entries/#{entry.id}/toggle_watched", headers: @headers

    assert_response :ok
    assert_equal false, JSON.parse(response.body)["watched"]
  end

  test "toggle_watched returns 404 on another user's entry" do
    entry = @other_user.calendar_entries.create!(tmdb_movie_id: @tmdb_movie_id, scheduled_on: "2026-07-15", title: "Fight Club", poster_path: "/fight_club.jpg", vote_average: 8.4, release_date: "1999-10-15")

    patch "/v1/calendar/entries/#{entry.id}/toggle_watched", headers: @headers

    assert_response :not_found
  end

  test "toggle_watched returns 401 without auth token" do
    entry = @user.calendar_entries.create!(tmdb_movie_id: @tmdb_movie_id, scheduled_on: "2026-07-15", title: "Fight Club", poster_path: "/fight_club.jpg", vote_average: 8.4, release_date: "1999-10-15")

    patch "/v1/calendar/entries/#{entry.id}/toggle_watched"

    assert_response :unauthorized
  end
end
