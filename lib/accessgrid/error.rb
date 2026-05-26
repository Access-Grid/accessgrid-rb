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

  # Raised when a SmartTap reveal envelope is missing fields or contains
  # non-base64 / non-PEM data.
  class InvalidEnvelopeError < Error; end

  # Raised when AES-GCM auth-tag verification fails while decrypting a
  # SmartTap reveal envelope (wrong key, tampered envelope, or wire-format
  # drift between server and SDK).
  class DecryptError < Error; end

  # additional error classes to match Python version
  class AccessGridError < Error; end
end
