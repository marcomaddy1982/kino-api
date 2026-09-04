class ListItemService
  class << self
    def add(list, tmdb_movie_id:)
      list.list_items.create!(tmdb_movie_id: tmdb_movie_id)
    rescue ActiveRecord::RecordInvalid
      raise KinoErrors::BadRequestError
    end

    def remove(list, tmdb_movie_id:)
      item = list.list_items.find_by!(tmdb_movie_id: tmdb_movie_id)
      item.destroy!
    rescue ActiveRecord::RecordNotFound
      raise KinoErrors::NotFoundError
    end

    def fetch_movies(list)
      list.list_items.filter_map do |item|
        TmdbMovieService.fetch_movie(item.tmdb_movie_id)
      rescue KinoErrors::NotFoundError
        item.destroy
        nil
      rescue StandardError => e
        Rails.logger.warn("Skipping unavailable list item #{item.tmdb_movie_id}: #{e.message}")
        nil
      end
    end
  end
end
