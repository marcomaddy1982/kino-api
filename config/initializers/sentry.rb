module SentryConfig
  # SENTRY_RELEASE wins, then Render's deploy commit. nil leaves Sentry's own
  # detection in place (git, in development). The image has no .git and Sentry
  # doesn't read Render's variable on its own, so without this events carry no
  # release (no per-deploy regressions, no suspect commits).
  def self.release(env = ENV)
    env["SENTRY_RELEASE"].presence || env["RENDER_GIT_COMMIT"].presence
  end
end

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.enabled_environments = %w[production]

  release = SentryConfig.release
  config.release = release if release

  # The trail of SQL, controller actions and outgoing TMDB calls leading up to
  # an error.
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # By default Sentry adds sentry-trace and baggage headers (which carry the
  # release and DSN public key) to every outgoing request, TMDB included. No
  # service of ours consumes them, so never propagate.
  config.trace_propagation_targets = []

  # filter_parameter_logging.rb already scrubs :email, :token, :passw, etc. —
  # sentry-rails reuses Rails' own parameter filter for request context, and
  # we don't send anything beyond that.
  config.send_default_pii = false

  # Breadcrumbs and events carry URL query strings and controller params, and
  # Rails' filter doesn't cover things like phone_number or a user's search
  # text. Only these harmless, useful ones keep their values; every other key
  # is sent as [Filtered].
  config.data_collection.url_query_params.mode = :allow_list
  config.data_collection.url_query_params.terms = %w[from to page sort_by]
end
