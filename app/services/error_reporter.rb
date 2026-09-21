# The one place unexpected errors are sent to Sentry, so that grouping stays
# consistent. Expected client errors (401/404/400) are never reported.
class ErrorReporter
  class << self
    def report(exception)
      Sentry.with_scope do |scope|
        tag_upstream(scope, exception) if exception.is_a?(KinoErrors::UpstreamError)
        Sentry.capture_exception(exception)
      end
    end

    private

    # Group upstream failures by what actually went wrong (the HTTP status, or
    # the underlying error class) so a bad token (401) and an outage (503) are
    # separate issues, and a failing movie id never splits an issue.
    def tag_upstream(scope, exception)
      origin = exception.upstream_status || exception.cause&.class&.name || "unknown"
      scope.set_fingerprint([ "upstream", origin.to_s ])
      scope.set_tags(upstream_status: exception.upstream_status.to_s) if exception.upstream_status
    end
  end
end
