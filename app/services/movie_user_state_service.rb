class MovieUserStateService
  class << self
    def for_movie(user, tmdb_id)
      {
        is_favourite: favourite?(user, tmdb_id),
        calendar_entries: calendar_entries(user, tmdb_id)
      }
    end

    private

    # Read-only on purpose: unlike ListService.find_or_create_favourites, a GET
    # must not create the user's Favourites list as a side effect.
    def favourite?(user, tmdb_id)
      ListItem.joins(:list).exists?(tmdb_movie_id: tmdb_id, lists: { user_id: user.id, is_favourite: true })
    end

    def calendar_entries(user, tmdb_id)
      user.calendar_entries
          .where(tmdb_movie_id: tmdb_id)
          .order(:scheduled_on, :id)
          .pluck(:id, :scheduled_on, :watched)
          .map { |id, scheduled_on, watched| { id: id, scheduled_on: scheduled_on, watched: watched } }
    end
  end
end
