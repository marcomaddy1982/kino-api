module V1
  class ListItemsController < ::ApplicationController
    before_action :set_list

    def index
      movies = @list.list_items.filter_map do |item|
        TmdbMovieService.fetch_movie(item.tmdb_movie_id)
      rescue StandardError
        nil
      end
      render json: movies, status: :ok
    end

    def create
      item = ListItemService.add(@list, tmdb_movie_id: params.require(:tmdb_movie_id))
      render json: { tmdbMovieId: item.tmdb_movie_id }, status: :created
    end

    def destroy
      ListItemService.remove(@list, tmdb_movie_id: params[:id])
      head :no_content
    end

    private

    def set_list
      @list = current_user.lists.find(params[:list_id])
    rescue ActiveRecord::RecordNotFound
      raise KinoErrors::NotFoundError
    end
  end
end
