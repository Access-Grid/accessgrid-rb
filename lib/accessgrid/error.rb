# frozen_string_literal: true

module AccessGrid
  # base error
  class Error < StandardError; end

  # descendant errors
  class AuthenticationError < Error; end
  class ResourceNotFoundError < Error; end
  class ValidationError < Error; end

  # additional error classes to match Python version
  class AccessGridError < Error; end
end
