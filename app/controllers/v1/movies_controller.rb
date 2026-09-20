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
      render json: movie.merge("user" => user_state(params[:id])), status: :ok
    end

    private

    # Secondary to the TMDB data: a failure here must not fail the whole page.
    # nil means "unknown" to the client, which is not the same as "no".
    def user_state(tmdb_id)
      MovieUserStateService.for_movie(current_user, tmdb_id)
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.error(e.full_message(highlight: false))
      nil
    end
  end
end
