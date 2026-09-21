module KinoErrors
  class AuthenticationError < StandardError; end
  class NotFoundError < StandardError; end
  class ForbiddenError < StandardError; end
  class BadRequestError < StandardError; end

  # A failure of a service we depend on (TMDB). upstream_status is the HTTP
  # status it answered with, or nil when there was no answer (timeout, etc.);
  # in that case the underlying error is available as #cause.
  class UpstreamError < StandardError
    attr_reader :upstream_status

    def initialize(message = nil, upstream_status: nil)
      super(message)
      @upstream_status = upstream_status
    end
  end
end
