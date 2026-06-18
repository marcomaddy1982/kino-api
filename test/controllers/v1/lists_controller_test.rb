require "test_helper"

class V1::ListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(tmdb_account_id: 123)
    @headers = auth_header
  end

  teardown do
    @user.destroy
  end

  # GET /v1/lists
  test "index returns all lists for the current user" do
    ListService.create(@user, name: "Watchlist")
    ListService.find_or_create_favourites(@user)

    get v1_lists_path, headers: @headers, as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 2, body.length
  end

  test "index returns 401 without auth header" do
    get v1_lists_path, as: :json
    assert_response :unauthorized
  end

  # POST /v1/lists
  test "create returns 201 and the new list" do
    post v1_lists_path, params: { name: "Horror" }, headers: @headers, as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Horror", body["name"]
    assert_equal false, body["isFavourite"]
  end

  test "create returns 400 without a name" do
    post v1_lists_path, params: {}, headers: @headers, as: :json
    assert_response :bad_request
  end

  # DELETE /v1/lists/:id
  test "destroy deletes a regular list" do
    list = ListService.create(@user, name: "Watchlist")
    delete v1_list_path(list), headers: @headers, as: :json
    assert_response :no_content
  end

  test "destroy returns 403 for the favourites list" do
    fav = ListService.find_or_create_favourites(@user)
    delete v1_list_path(fav), headers: @headers, as: :json
    assert_response :forbidden
  end

  test "destroy returns 404 for a list belonging to another user" do
    other_user = User.create!(tmdb_account_id: 456)
    other_list = ListService.create(other_user, name: "Someone else's list")

    delete v1_list_path(other_list), headers: @headers, as: :json
    assert_response :not_found
  ensure
    other_user.destroy
  end
end
