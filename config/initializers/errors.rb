module KinoErrors
  class AuthenticationError < StandardError; end
  class NotFoundError < StandardError; end
  class ForbiddenError < StandardError; end
  class BadRequestError < StandardError; end
end
