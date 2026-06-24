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

  TMDB_DETAILS = { 550 => { "title" => "Fight Club", "poster_path" => "/fc.jpg", "vote_average" => 8.4, "release_date" => "1999-10-15" } }.freeze

  test "renders expected camelCase keys" do
    result = ListItemBlueprint.render_as_hash(@item, tmdb_details: TMDB_DETAILS)
    assert result.key?(:id)
    assert result.key?(:tmdbMovieId)
    assert result.key?(:createdAt)
    assert result.key?(:title)
    assert result.key?(:posterPath)
    assert result.key?(:voteAverage)
    assert result.key?(:releaseDate)
  end

  test "renders correct values" do
    result = ListItemBlueprint.render_as_hash(@item, tmdb_details: TMDB_DETAILS)
    assert_equal @item.id, result[:id]
    assert_equal 550, result[:tmdbMovieId]
    assert_equal "Fight Club", result[:title]
    assert_equal "/fc.jpg", result[:posterPath]
    assert_equal 8.4, result[:voteAverage]
    assert_equal "1999-10-15", result[:releaseDate]
  end

  test "renders nil fields when tmdb_details missing" do
    result = ListItemBlueprint.render_as_hash(@item, tmdb_details: {})
    assert_nil result[:title]
    assert_nil result[:posterPath]
    assert_nil result[:voteAverage]
    assert_nil result[:releaseDate]
  end
end
