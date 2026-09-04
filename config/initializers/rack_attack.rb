class Rack::Attack
  # 5 login attempts for the same email per 20s — stops hammering one account
  throttle("login/email", limit: 5, period: 20) do |req|
    next unless req.path == "/v1/auth/login" && req.post?

    ActionDispatch::Request.new(req.env).params["email"]&.downcase&.strip
  end

  # 20 login attempts per IP per minute — stops rotating through many emails
  throttle("login/ip", limit: 20, period: 60) do |req|
    req.ip if req.path == "/v1/auth/login" && req.post?
  end

  # 5 registrations per IP per hour — stops signup spam
  throttle("register/ip", limit: 5, period: 3600) do |req|
    req.ip if req.path == "/v1/auth/register" && req.post?
  end

  # Keep the Kino error shape ({ "error": "..." }) instead of rack-attack's default body
  self.throttled_responder = lambda do |_request|
    [ 429, { "Content-Type" => "application/json" }, [ { error: "Too many requests" }.to_json ] ]
  end
end

Rails.application.config.middleware.use Rack::Attack
