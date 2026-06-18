require "test_helper"

class ListItemBlueprintTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(tmdb_account_id: 999)
    @list = ListService.create(@user, name: "Watchlist")
    @item = ListItemService.add(@list, tmdb_movie_id: 550)
  end

  teardown do
    @user.destroy
  end

  test "renders expected camelCase keys" do
    result = ListItemBlueprint.render_as_hash(@item)
    assert result.key?(:id)
    assert result.key?(:tmdbMovieId)
    assert result.key?(:createdAt)
  end

  test "renders correct values" do
    result = ListItemBlueprint.render_as_hash(@item)
    assert_equal @item.id, result[:id]
    assert_equal 550, result[:tmdbMovieId]
  end
end
