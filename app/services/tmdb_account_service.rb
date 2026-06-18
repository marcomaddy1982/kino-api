class TmdbAccountService
  BASE_URL = ENV.fetch("TMDB_API_BASE_URL")
  API_KEY = ENV.fetch("TMDB_API_KEY")

  class << self
    def fetch_account_id(session_id)
      response = connection.get("/3/account") do |req|
        req.params["api_key"] = API_KEY
        req.params["session_id"] = session_id
      end

      raise KinoErrors::AuthenticationError unless response.success?

      body = JSON.parse(response.body)
      body["id"] or raise KinoErrors::AuthenticationError
    rescue Faraday::Error
      raise KinoErrors::AuthenticationError
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL)
    end
  end
end
