require "test_helper"

class ListItemServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "user@example.com", password: "Password1", name: "Test User", phone_number: "+391234567890")
    @list = ListService.create(@user, name: "Watchlist")
  end

  teardown do
    @user.destroy
  end

  test "add creates a list item" do
    item = ListItemService.add(@list, tmdb_movie_id: 550)
    assert_equal 550, item.tmdb_movie_id
    assert_equal @list.id, item.list_id
  end

  test "add raises BadRequestError for a duplicate movie" do
    ListItemService.add(@list, tmdb_movie_id: 550)
    assert_raises(KinoErrors::BadRequestError) { ListItemService.add(@list, tmdb_movie_id: 550) }
  end

  test "remove deletes the list item" do
    ListItemService.add(@list, tmdb_movie_id: 550)
    ListItemService.remove(@list, tmdb_movie_id: 550)
    assert_equal 0, @list.list_items.count
  end

  test "remove raises NotFoundError for a missing movie" do
    assert_raises(KinoErrors::NotFoundError) { ListItemService.remove(@list, tmdb_movie_id: 999) }
  end

  test "fetch_movies removes the item when TMDB reports it permanently gone" do
    item = ListItemService.add(@list, tmdb_movie_id: 550)
    stub_tmdb("movie/550", status: 404, body: { status_code: 34 })

    result = ListItemService.fetch_movies(@list)

    assert_equal [], result
    assert_not ListItem.exists?(item.id)
  end

  test "fetch_movies keeps the item when TMDB is temporarily unavailable" do
    item = ListItemService.add(@list, tmdb_movie_id: 550)
    stub_request(:get, "#{ENV["TMDB_API_BASE_URL"]}/movie/550").to_timeout

    result = ListItemService.fetch_movies(@list)

    assert_equal [], result
    assert ListItem.exists?(item.id)
  end
end
