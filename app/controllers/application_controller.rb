class ApplicationController < ActionController::API
  before_action :authenticate!

  rescue_from KinoErrors::AuthenticationError,    with: :render_unauthorized
  rescue_from KinoErrors::NotFoundError,          with: :render_not_found
  rescue_from KinoErrors::ForbiddenError,         with: :render_forbidden
  rescue_from KinoErrors::BadRequestError,        with: :render_bad_request
  rescue_from KinoErrors::UpstreamError,          with: :render_bad_gateway
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def authenticate!
    token = bearer_token
    raise KinoErrors::AuthenticationError unless token

    payload = JwtService.decode(token)
    @current_user = User.find(payload[:sub])
    # Id only, no email or name: enough to count affected users and to find
    # the reporter's errors, with send_default_pii still off.
    Sentry.set_user(id: @current_user.id.to_s)
  rescue ActiveRecord::RecordNotFound
    raise KinoErrors::AuthenticationError
  end

  def current_user
    @current_user
  end

  def bearer_token
    header = request.headers["Authorization"]
    header&.split(" ")&.last
  end

  def render_unauthorized(exception)
    log_reason(exception)
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def render_not_found(exception)
    log_reason(exception)
    render json: { error: "Not found" }, status: :not_found
  end

  def render_forbidden(exception)
    log_reason(exception)
    render json: { error: "Forbidden" }, status: :forbidden
  end

  def render_bad_request(exception)
    log_reason(exception)
    render json: { error: "Bad request" }, status: :bad_request
  end

  # Unlike the 4xx handlers above, this is our dependency failing, not the
  # client's mistake, so it is reported to Sentry.
  def render_bad_gateway(exception)
    ErrorReporter.report(exception)
    render json: { error: "Upstream service unavailable" }, status: :bad_gateway
  end

  # The client only ever sees a generic message, so the real reason (a
  # duplicate day, an expired token...) is kept in the log. It is the
  # original error a service turned into a KinoErrors one, or the exception's
  # own message when it says more than its class name. Never sent to Sentry:
  # these are expected errors. Messages can echo request input (an id in a
  # RecordNotFound), so control characters are stripped and the length capped
  # to keep a crafted value from forging log lines.
  def log_reason(exception)
    reason = exception.cause || exception
    return if reason.message == reason.class.name

    Rails.logger.warn("#{exception.class}: #{reason.message.gsub(/[[:cntrl:]]+/, " ").truncate(300)}")
  end
end
