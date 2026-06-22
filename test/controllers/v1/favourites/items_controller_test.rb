require "test_helper"

class V1::Favourites::ItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(tmdb_account_id: 123)
    @favourites = ListService.find_or_create_favourites(@user)
    @headers = auth_header
  end

  teardown do
    @user.destroy
  end

  # GET /v1/favourites/items/:tmdb_movie_id
  test "show returns is_favourite true when movie is in favourites" do
    ListItemService.add(@favourites, tmdb_movie_id: 550)
    get v1_favourites_item_path(550), headers: @headers, as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal true, body["is_favourite"]
  end

  test "show returns is_favourite false when movie is not in favourites" do
    get v1_favourites_item_path(550), headers: @headers, as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal false, body["is_favourite"]
  end

  test "show returns 401 without auth header" do
    get v1_favourites_item_path(550), as: :json

    assert_response :unauthorized
  end

  # POST /v1/favourites/items/:tmdb_movie_id/toggle
  test "toggle adds movie to favourites when not present" do
    post v1_favourites_toggle_item_path(550), headers: @headers, as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal true, body["is_favourite"]
    assert @favourites.list_items.exists?(tmdb_movie_id: 550)
  end

  test "toggle removes movie from favourites when already present" do
    ListItemService.add(@favourites, tmdb_movie_id: 550)
    post v1_favourites_toggle_item_path(550), headers: @headers, as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal false, body["is_favourite"]
    assert_not @favourites.list_items.exists?(tmdb_movie_id: 550)
  end

  test "toggle returns 401 without auth header" do
    post v1_favourites_toggle_item_path(550), as: :json

    assert_response :unauthorized
  end
end
