class ApplicationController < ActionController::API
  before_action :authenticate!

  rescue_from KinoErrors::AuthenticationError, with: :render_unauthorized
  rescue_from KinoErrors::NotFoundError,       with: :render_not_found
  rescue_from KinoErrors::ForbiddenError,      with: :render_forbidden
  rescue_from KinoErrors::BadRequestError,     with: :render_bad_request

  private

  def authenticate!
    token = bearer_token
    raise KinoErrors::AuthenticationError unless token

    payload = JwtService.decode(token)
    @current_user = User.find(payload[:sub])
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

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def render_not_found
    render json: { error: "Not found" }, status: :not_found
  end

  def render_forbidden
    render json: { error: "Forbidden" }, status: :forbidden
  end

  def render_bad_request
    render json: { error: "Bad request" }, status: :bad_request
  end
end
