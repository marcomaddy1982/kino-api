class ApplicationController < ActionController::API
  before_action :authenticate!

  rescue_from KinoErrors::AuthenticationError, with: :render_unauthorized
  rescue_from KinoErrors::NotFoundError,       with: :render_not_found
  rescue_from KinoErrors::ForbiddenError,      with: :render_forbidden
  rescue_from KinoErrors::BadRequestError,     with: :render_bad_request

  private

  def authenticate!
    session_id = bearer_token
    raise KinoErrors::AuthenticationError unless session_id

    account_id = TmdbAccountService.fetch_account_id(session_id)
    @current_user = User.find_or_create_by!(tmdb_account_id: account_id)
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
