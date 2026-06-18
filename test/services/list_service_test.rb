require "test_helper"

class ListServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(tmdb_account_id: 999)
  end

  teardown do
    @user.destroy
  end

  test "create builds a regular list for the user" do
    list = ListService.create(@user, name: "Horror")
    assert_equal "Horror", list.name
    assert_equal false, list.is_favourite
    assert_equal @user.id, list.user_id
  end

  test "find_or_create_favourites creates the favourites list" do
    list = ListService.find_or_create_favourites(@user)
    assert_equal "Favourites", list.name
    assert list.is_favourite
  end

  test "find_or_create_favourites does not duplicate the favourites list" do
    first  = ListService.find_or_create_favourites(@user)
    second = ListService.find_or_create_favourites(@user)
    assert_equal first.id, second.id
  end

  test "destroy deletes a regular list" do
    list = ListService.create(@user, name: "Watchlist")
    ListService.destroy(list)
    assert_raises(ActiveRecord::RecordNotFound) { List.find(list.id) }
  end

  test "destroy raises ForbiddenError for the favourites list" do
    fav = ListService.find_or_create_favourites(@user)
    assert_raises(KinoErrors::ForbiddenError) { ListService.destroy(fav) }
  end
end
