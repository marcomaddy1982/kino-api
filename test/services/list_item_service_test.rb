require "test_helper"

class ListItemServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(tmdb_account_id: 999)
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
end
