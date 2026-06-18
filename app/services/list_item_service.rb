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
  end
end
