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
    result = ListItemBlueprint.render_as_hash(@item, tmdb_details: { 550 => { "title" => "Fight Club", "poster_path" => "/fc.jpg" } })
    assert result.key?(:id)
    assert result.key?(:tmdbMovieId)
    assert result.key?(:createdAt)
    assert result.key?(:title)
    assert result.key?(:posterPath)
  end

  test "renders correct values" do
    result = ListItemBlueprint.render_as_hash(@item, tmdb_details: { 550 => { "title" => "Fight Club", "poster_path" => "/fc.jpg" } })
    assert_equal @item.id, result[:id]
    assert_equal 550, result[:tmdbMovieId]
    assert_equal "Fight Club", result[:title]
    assert_equal "/fc.jpg", result[:posterPath]
  end

  test "renders nil title and poster_path when tmdb_details missing" do
    result = ListItemBlueprint.render_as_hash(@item, tmdb_details: {})
    assert_nil result[:title]
    assert_nil result[:posterPath]
  end
end
