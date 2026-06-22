module V1
  module Favourites
    class ItemsController < ::ApplicationController
      def show
        favourites = ListService.find_or_create_favourites(current_user)
        is_favourite = favourites.list_items.exists?(tmdb_movie_id: params[:tmdb_movie_id])
        render json: { isFavourite: is_favourite }, status: :ok
      end

      def toggle
        favourites = ListService.find_or_create_favourites(current_user)
        item = favourites.list_items.find_by(tmdb_movie_id: params[:tmdb_movie_id])

        if item
          item.destroy!
          render json: { isFavourite: false }, status: :ok
        else
          favourites.list_items.create!(tmdb_movie_id: params[:tmdb_movie_id])
          render json: { isFavourite: true }, status: :ok
        end
      end
    end
  end
end
