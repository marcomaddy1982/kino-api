module V1
  class ListItemsController < ::ApplicationController
    before_action :set_list

    def index
      items = @list.list_items
      tmdb_details = items.each_with_object({}) do |item, hash|
        hash[item.tmdb_movie_id] = TmdbMovieService.fetch_movie(item.tmdb_movie_id)
      rescue StandardError
        hash[item.tmdb_movie_id] = {}
      end
      render json: ListItemBlueprint.render(items, root: false, tmdb_details: tmdb_details), status: :ok
    end

    def create
      item = ListItemService.add(@list, tmdb_movie_id: params.require(:tmdb_movie_id))
      render json: ListItemBlueprint.render(item), status: :created
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
