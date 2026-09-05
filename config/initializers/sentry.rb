Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.enabled_environments = %w[production]

  # filter_parameter_logging.rb already scrubs :email, :token, :passw, etc. —
  # sentry-rails reuses Rails' own parameter filter for request context, and
  # we don't send anything beyond that.
  config.send_default_pii = false
end
