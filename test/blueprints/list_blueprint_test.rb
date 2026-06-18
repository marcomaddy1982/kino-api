require "test_helper"

class ListBlueprintTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(tmdb_account_id: 999)
    @list = ListService.create(@user, name: "Watchlist")
  end

  teardown do
    @user.destroy
  end

  test "renders expected camelCase keys" do
    result = ListBlueprint.render_as_hash(@list)
    assert result.key?(:id)
    assert result.key?(:name)
    assert result.key?(:isFavourite)
    assert result.key?(:createdAt)
  end

  test "renders correct values" do
    result = ListBlueprint.render_as_hash(@list)
    assert_equal @list.id, result[:id]
    assert_equal "Watchlist", result[:name]
    assert_equal false, result[:isFavourite]
  end
end
