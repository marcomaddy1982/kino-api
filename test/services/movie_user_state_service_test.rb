require "test_helper"

class MovieUserStateServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "user@example.com", password: "Password1", name: "Test User", phone_number: "+391234567890")
    @other_user = User.create!(email: "other@example.com", password: "Password1", name: "Other User", phone_number: "+390987654321")
  end

  teardown do
    @user.destroy
    @other_user.destroy
  end

  test "reports nothing for a movie the user has not touched" do
    assert_equal({ is_favourite: false, calendar_entries: [] }, MovieUserStateService.for(@user, 550))
  end

  test "reports the movie as a favourite" do
    ListService.find_or_create_favourites(@user).list_items.create!(tmdb_movie_id: 550)

    assert MovieUserStateService.for(@user, 550)[:is_favourite]
  end

  test "ignores a regular list that contains the movie" do
    ListService.create(@user, name: "Horror").list_items.create!(tmdb_movie_id: 550)

    assert_not MovieUserStateService.for(@user, 550)[:is_favourite]
  end

  test "ignores another user's favourite" do
    ListService.find_or_create_favourites(@other_user).list_items.create!(tmdb_movie_id: 550)

    assert_not MovieUserStateService.for(@user, 550)[:is_favourite]
  end

  test "does not create the favourites list as a side effect" do
    assert_no_difference -> { List.count } do
      MovieUserStateService.for(@user, 550)
    end
  end

  test "lists every scheduled day for the movie, ordered by date" do
    later = @user.calendar_entries.create!(tmdb_movie_id: 550, scheduled_on: "2026-09-20", title: "Fight Club")
    earlier = @user.calendar_entries.create!(tmdb_movie_id: 550, scheduled_on: "2026-09-17", title: "Fight Club", watched: true)

    entries = MovieUserStateService.for(@user, 550)[:calendar_entries]

    assert_equal [
      { id: earlier.id, scheduled_on: Date.new(2026, 9, 17), watched: true },
      { id: later.id, scheduled_on: Date.new(2026, 9, 20), watched: false }
    ], entries
  end

  test "excludes other movies and other users' entries" do
    @user.calendar_entries.create!(tmdb_movie_id: 999, scheduled_on: "2026-09-17", title: "Other Movie")
    @other_user.calendar_entries.create!(tmdb_movie_id: 550, scheduled_on: "2026-09-17", title: "Fight Club")

    assert_equal [], MovieUserStateService.for(@user, 550)[:calendar_entries]
  end
end
