class TmdbMovieService
  API_BASE_URL = ENV.fetch("TMDB_API_BASE_URL")
  ACCESS_TOKEN = ENV.fetch("TMDB_ACCESS_TOKEN")

  DEFAULT_SORT  = "primary_release_date.desc"
  ALLOWED_SORTS = %w[
    primary_release_date.desc primary_release_date.asc
    popularity.desc vote_average.desc
  ].freeze
  MAX_PAGE = 500

  class << self
    def fetch_movie(tmdb_movie_id)
      get("movie/#{tmdb_movie_id}")
    end

    def discover(page: 1, sort_by: DEFAULT_SORT)
      sort_by = DEFAULT_SORT unless ALLOWED_SORTS.include?(sort_by)

      get("discover/movie",
        page: clamp_page(page),
        sort_by: sort_by,
        include_adult: false,
        language: "en-US",
        "primary_release_date.lte": Date.current.iso8601)
    end

    def search(query:, page: 1)
      query = query.to_s.strip
      raise KinoErrors::BadRequestError if query.blank?

      get("search/movie",
        query: query,
        page: clamp_page(page),
        include_adult: false,
        language: "en-US")
    end

    private

    def get(path, params = {})
      response = connection.get(path, params) do |req|
        req.headers["Authorization"] = "Bearer #{ACCESS_TOKEN}"
        req.headers["Accept"] = "application/json"
      end

      raise KinoErrors::NotFoundError if response.status == 404

      unless response.success?
        # A 4xx other than auth/rate-limit means TMDB rejected what we sent,
        # which comes from the caller's input: a 400, not an upstream outage
        # (and not something to report to Sentry).
        raise KinoErrors::BadRequestError, "TMDB rejected the request (#{response.status})" if rejected_input?(response.status)

        raise KinoErrors::UpstreamError.new("TMDB responded #{response.status}", upstream_status: response.status)
      end

      JSON.parse(response.body)
    rescue Faraday::Error, JSON::ParserError, TypeError => e
      Rails.logger.error(e.full_message(highlight: false))
      # Not reported here: whoever handles the UpstreamError reports it once,
      # with this error available as its cause.
      raise KinoErrors::UpstreamError, "TMDB request failed"
    end

    # 401/403 mean our TMDB credentials are wrong and 429 that we are rate
    # limited: those are ours to fix, so they stay upstream failures.
    def rejected_input?(status)
      status.between?(400, 499) && ![ 401, 403, 429 ].include?(status)
    end

    def clamp_page(page)
      page.to_i.clamp(1, MAX_PAGE)
    end

    def connection
      @connection ||= Faraday.new(url: API_BASE_URL)
    end
  end
end
