module V1
  class MoviesController < ::ApplicationController
    def index
      movies = TmdbMovieService.discover(
        page: params.fetch(:page, 1),
        sort_by: params.fetch(:sort_by, TmdbMovieService::DEFAULT_SORT)
      )
      render json: movies, status: :ok
    end

    def search
      movies = TmdbMovieService.search(
        query: params.require(:query),
        page: params.fetch(:page, 1)
      )
      render json: movies, status: :ok
    end

    def show
      movie = TmdbMovieService.fetch_movie(params[:id])
      render json: movie, status: :ok
    end
  end
end
