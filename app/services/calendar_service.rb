class CalendarService
  class << self
    def add(user, tmdb_movie_id:, scheduled_on:)
      movie = TmdbMovieService.fetch_movie(tmdb_movie_id)
      raise KinoErrors::NotFoundError unless movie

      user.calendar_entries.create!(
        tmdb_movie_id: tmdb_movie_id,
        scheduled_on: scheduled_on,
        title: movie["title"],
        poster_path: movie["poster_path"],
        vote_average: movie["vote_average"],
        release_date: movie["release_date"]
      )
    rescue ActiveRecord::RecordInvalid
      raise KinoErrors::BadRequestError
    end

    def reschedule(user, id:, scheduled_on:)
      entry = user.calendar_entries.find(id)
      entry.update!(scheduled_on: scheduled_on)
      entry
    rescue ActiveRecord::RecordNotFound
      raise KinoErrors::NotFoundError
    rescue ActiveRecord::RecordInvalid
      raise KinoErrors::BadRequestError
    end

    def remove(user, id:)
      entry = user.calendar_entries.find(id)
      entry.destroy!
    rescue ActiveRecord::RecordNotFound
      raise KinoErrors::NotFoundError
    end

    def toggle_watched(user, id:)
      entry = user.calendar_entries.find(id)
      entry.update!(watched: !entry.watched)
      entry
    rescue ActiveRecord::RecordNotFound
      raise KinoErrors::NotFoundError
    end

    def entries_for_month(user, year:, month:)
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month

      user.calendar_entries
          .where(scheduled_on: start_date..end_date)
          .order(:scheduled_on)
          .group_by(&:scheduled_on)
    end
  end
end
