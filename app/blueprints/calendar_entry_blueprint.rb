class CalendarEntryBlueprint < Blueprinter::Base
  fields :id, :tmdb_movie_id, :title, :poster_path, :vote_average, :release_date, :watched, :scheduled_on
end
