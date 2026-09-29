module KinoErrors
  class AuthenticationError < StandardError; end
  class NotFoundError < StandardError; end
  class ForbiddenError < StandardError; end
  class BadRequestError < StandardError; end

  # Carries per-field validation messages straight to the client, unlike the
  # other 4xx errors here, whose real reason is deliberately kept server-side.
  class ValidationError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super(errors.to_s)
    end
  end

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
