require "test_helper"

class SentryConfigTest < ActiveSupport::TestCase
  test "records SQL/controller and outgoing HTTP breadcrumbs" do
    assert_includes Sentry.configuration.breadcrumbs_logger, :active_support_logger
    assert_includes Sentry.configuration.breadcrumbs_logger, :http_logger
  end

  test "keeps PII off" do
    assert_equal false, Sentry.configuration.send_default_pii
  end

  SENTRY_HEADERS = %w[sentry-trace baggage].freeze

  # Makes a real request to a throwaway local server and returns the header
  # names it received. (WebMock stubs would bypass Sentry's Net::HTTP patch, so
  # they can't show what actually goes out on the wire.)
  def outgoing_request_headers
    server = TCPServer.new("127.0.0.1", 0)
    received = +""
    thread = Thread.new do
      client = server.accept
      while (line = client.gets) && line != "\r\n"
        received << line
      end
      client.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}")
      client.close
    end

    WebMock.disable_net_connect!(allow_localhost: true)
    Net::HTTP.get(URI("http://127.0.0.1:#{server.addr[1]}/movie/550"))
    thread.join(2)
    received.lines.drop(1).map { |line| line.split(":").first.downcase }
  ensure
    server&.close
    WebMock.disable_net_connect!
  end

  test "never adds Sentry trace headers to outgoing requests such as TMDB's" do
    assert_empty Sentry.configuration.trace_propagation_targets
    assert_empty(SENTRY_HEADERS & outgoing_request_headers)
  end

  test "the header check would notice propagation if it were switched on" do
    original = Sentry.configuration.trace_propagation_targets
    Sentry.configuration.trace_propagation_targets = [ /.*/ ]

    assert_not_empty(SENTRY_HEADERS & outgoing_request_headers)
  ensure
    Sentry.configuration.trace_propagation_targets = original
  end

  test "release: SENTRY_RELEASE wins over Render's commit" do
    assert_equal "v1", SentryConfig.release({ "SENTRY_RELEASE" => "v1", "RENDER_GIT_COMMIT" => "abc" })
  end

  test "release: falls back to Render's deploy commit" do
    assert_equal "abc123", SentryConfig.release({ "RENDER_GIT_COMMIT" => "abc123" })
  end

  test "release: nil when neither is set, so Sentry's own detection stays in place" do
    assert_nil SentryConfig.release({})
  end

  test "release: an empty variable counts as unset" do
    assert_equal "abc", SentryConfig.release({ "SENTRY_RELEASE" => "", "RENDER_GIT_COMMIT" => "abc" })
    assert_nil SentryConfig.release({ "SENTRY_RELEASE" => "", "RENDER_GIT_COMMIT" => "" })
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
