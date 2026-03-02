# frozen_string_literal: true

module AccessGrid
  # base error
  class Error < StandardError; end

  # Raised when API credentials are invalid.
  class AuthenticationError < Error; end

  # Raised when a requested resource does not exist.
  class ResourceNotFoundError < Error; end

  # Raised when request parameters fail validation.
  class ValidationError < Error; end

  # additional error classes to match Python version
  class AccessGridError < Error; end
end
