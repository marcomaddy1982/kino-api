require "test_helper"

class SentryConfigTest < ActiveSupport::TestCase
  test "records SQL/controller and outgoing HTTP breadcrumbs" do
    assert_includes Sentry.configuration.breadcrumbs_logger, :active_support_logger
    assert_includes Sentry.configuration.breadcrumbs_logger, :http_logger
  end

  test "keeps PII off" do
    assert_equal false, Sentry.configuration.send_default_pii
  end

  test "only the allow-listed query params keep their values" do
    filtered = Sentry.configuration.data_collection.url_query_params.filter({
      "from" => "2026-09-01",
      "page" => "2",
      "query" => "a private search",
      "phone_number" => "+391234567890",
      "name" => "Test User"
    })

    assert_equal "2026-09-01", filtered["from"]
    assert_equal "2", filtered["page"]
    assert_not_includes filtered.values, "a private search"
    assert_not_includes filtered.values, "+391234567890"
    assert_not_includes filtered.values, "Test User"
    assert_equal %w[from page query phone_number name].sort, filtered.keys.sort
  end
end
