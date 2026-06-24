class TmdbMovieService
  API_BASE_URL = "https://api.themoviedb.org"
  ACCESS_TOKEN = ENV.fetch("TMDB_ACCESS_TOKEN")

  class << self
    def fetch_movie(tmdb_movie_id)
      response = connection.get("/movie/#{tmdb_movie_id}") do |req|
        req.headers["Authorization"] = "Bearer #{ACCESS_TOKEN}"
        req.headers["Accept"] = "application/json"
      end

      raise KinoErrors::NotFoundError unless response.success?

      JSON.parse(response.body)
    rescue Faraday::Error => e
      raise StandardError, "TMDB request failed: #{e.message}"
    end

    private

    def connection
      @connection ||= Faraday.new(url: API_BASE_URL)
    end
  end
end
