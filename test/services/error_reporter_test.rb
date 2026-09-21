require "test_helper"

class ErrorReporterTest < ActiveSupport::TestCase
  # Runs the block's report while capturing what the scope held at the moment
  # the exception was handed to Sentry.
  def report_and_capture_scope(exception)
    captured = nil
    Sentry.stubs(:capture_exception).with do |e|
      scope = Sentry.get_current_scope
      captured = { exception: e, fingerprint: scope.fingerprint, tags: scope.tags }
      true
    end

    ErrorReporter.report(exception)
    captured
  end

  test "sends the exception to Sentry" do
    error = StandardError.new("boom")
    Sentry.expects(:capture_exception).with(error).once

    ErrorReporter.report(error)
  end

  test "groups an upstream failure by its HTTP status and tags it" do
    error = KinoErrors::UpstreamError.new("TMDB responded 503", upstream_status: 503)

    captured = report_and_capture_scope(error)

    assert_same error, captured[:exception]
    assert_equal %w[upstream 503], captured[:fingerprint]
    assert_equal "503", captured[:tags][:upstream_status]
  end

  test "groups an upstream failure with no status by its underlying error class" do
    error = begin
      begin
        raise Faraday::TimeoutError, "slow"
      rescue Faraday::Error
        raise KinoErrors::UpstreamError, "TMDB request failed"
      end
    rescue KinoErrors::UpstreamError => e
      e
    end

    captured = report_and_capture_scope(error)

    assert_equal [ "upstream", "Faraday::TimeoutError" ], captured[:fingerprint]
    assert_not captured[:tags].key?(:upstream_status)
  end

  test "different statuses are different issues, and the movie id never splits one" do
    a = report_and_capture_scope(KinoErrors::UpstreamError.new("TMDB responded 401", upstream_status: 401))
    b = report_and_capture_scope(KinoErrors::UpstreamError.new("TMDB responded 503", upstream_status: 503))

    assert_not_equal a[:fingerprint], b[:fingerprint]
  end

  test "leaves the default grouping for other errors" do
    captured = report_and_capture_scope(StandardError.new("boom"))

    assert_empty captured[:fingerprint]
  end

  test "an upstream failure with neither status nor cause still groups" do
    captured = report_and_capture_scope(KinoErrors::UpstreamError.new("?"))

    assert_equal %w[upstream unknown], captured[:fingerprint]
  end
end
