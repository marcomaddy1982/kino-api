Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.enabled_environments = %w[production]

  # Tie every event to the deploy that produced it (regression detection,
  # suspect commits). The image has no .git, so Sentry can't detect it, and it
  # doesn't read Render's variable on its own.
  release = ENV["SENTRY_RELEASE"] || ENV["RENDER_GIT_COMMIT"]
  config.release = release if release

  # The trail of SQL, controller actions and outgoing TMDB calls leading up to
  # an error.
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

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
