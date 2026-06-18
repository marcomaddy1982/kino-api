require "test_helper"

class V1::ListItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(tmdb_account_id: 123)
    @list = ListService.create(@user, name: "Watchlist")
    @headers = auth_header
  end

  teardown do
    @user.destroy
  end

  # POST /v1/lists/:list_id/items
  test "create adds a movie to the list" do
    post v1_list_list_items_path(@list), params: { tmdb_movie_id: 550 }, headers: @headers, as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal 550, body["tmdbMovieId"]
  end

  test "create returns 400 for a duplicate movie" do
    ListItemService.add(@list, tmdb_movie_id: 550)
    post v1_list_list_items_path(@list), params: { tmdb_movie_id: 550 }, headers: @headers, as: :json

    assert_response :bad_request
  end

  test "create returns 404 for a list belonging to another user" do
    other_user = User.create!(tmdb_account_id: 456)
    other_list = ListService.create(other_user, name: "Other")

    post v1_list_list_items_path(other_list), params: { tmdb_movie_id: 550 }, headers: @headers, as: :json

    assert_response :not_found
  ensure
    other_user.destroy
  end

  # DELETE /v1/lists/:list_id/items/:id
  test "destroy removes a movie from the list" do
    ListItemService.add(@list, tmdb_movie_id: 550)
    delete v1_list_list_item_path(@list, 550), headers: @headers, as: :json

    assert_response :no_content
  end

  test "destroy returns 404 for a movie not in the list" do
    delete v1_list_list_item_path(@list, 999), headers: @headers, as: :json

    assert_response :not_found
  end

  test "create returns 401 without auth header" do
    post v1_list_list_items_path(@list), params: { tmdb_movie_id: 550 }, as: :json
    assert_response :unauthorized
  end
end
