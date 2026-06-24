class TmdbAccountService
  API_BASE_URL = "https://api.themoviedb.org"
  ACCESS_TOKEN = ENV.fetch("TMDB_ACCESS_TOKEN")

  class << self
    def fetch_account_id(session_id)
      response = connection.get("/3/account") do |req|
        req.params["session_id"] = session_id
        req.headers["Authorization"] = "Bearer #{ACCESS_TOKEN}"
        req.headers["Accept"] = "application/json"
      end

      raise KinoErrors::AuthenticationError unless response.success?

      body = JSON.parse(response.body)
      body["id"] or raise KinoErrors::AuthenticationError
    rescue Faraday::Error
      raise KinoErrors::AuthenticationError
    end

    private

    def connection
      @connection ||= Faraday.new(url: API_BASE_URL)
    end
  end
end
