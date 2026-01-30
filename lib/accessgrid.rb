# frozen_string_literal: true

# lib/accessgrid.rb
require 'base64'
require 'json'
require 'net/http'
require 'openssl'
require 'uri'

require_relative 'accessgrid/version'
require_relative 'accessgrid/access_cards'
require_relative 'accessgrid/console'

module AccessGrid
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class ResourceNotFoundError < Error; end
  class ValidationError < Error; end

  # Additional error classes to match Python version
  class AccessGridError < Error; end

  class Client
    attr_reader :access_cards, :account_id, :api_secret, :api_host, :console

    def initialize(account_id, api_secret, api_host = 'https://api.accessgrid.com')
      raise ArgumentError, 'Account ID is required' if account_id.nil? || account_id.empty?
      raise ArgumentError, 'API Secret is required' if api_secret.nil? || api_secret.empty?

      @account_id = account_id
      @api_secret = api_secret
      @api_host = api_host.chomp('/')
      @access_cards = AccessCards.new(self)
      @console = Console.new(self)
    end

    def make_request(method, path, body = nil, params = nil)
      uri = URI.parse("#{api_host}#{path}")
      uri.query = URI.encode_www_form(params) if params && !params.empty?

      # Create request object based on method
      request = generate_request(method, uri, account_id)

      # generate a payload, and maybe generate a new request for a get or post signature
      payload, new_request, new_uri = generate_signature_payload_and_request(method, uri, body, path, account_id,
                                                                             params)
      request = new_request || request
      uri = new_uri || uri

      perform_request_and_handle_response(method, request, uri, body, payload)
    end

    private

    def perform_request_and_handle_response(method_name, request, uri, body, payload)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'

      # Generate signature
      request['X-PAYLOAD-SIG'] = generate_signature(payload)

      # Add the body to the request
      request.body = body.to_json if body && method_name != :get

      # Make request
      response = http.request(request)

      # Parse response
      handle_response(response)
    end

    def handle_response(response)
      case response.code.to_i
      when 200, 201, 202 then JSON.parse(response.body)
      when 401 then raise AuthenticationError, 'Invalid credentials'
      when 402 then raise Error, 'Insufficient account balance'
      when 404 then raise ResourceNotFoundError, 'Resource not found'
      when 422 then raise ValidationError, JSON.parse(response.body)['message']
      else
        process_unhandled_response(response)
      end
    end

    def process_unhandled_response(response)
      error_message = response.body.empty? ? "HTTP Status #{response.code}" : response.body

      begin
        error_data = JSON.parse(response.body)
        error_message = error_data['message'] if error_data['message']
      rescue JSON::ParserError
        # If it's not valid JSON, just use the response body
      end

      raise Error, "API request failed: #{error_message}"
    end

    def generate_signature_payload_and_request(method_name, uri, body, path, account_id, params)
      payload = body&.to_json || ''
      request = nil

      return [payload, request] unless method_name == :get || (method_name == :post && (body.nil? || body.empty?))

      resource_id = generate_resource_id(method_name, body, path)
      payload = generate_signature_payload(resource_id)
      request = generate_signature_request(method_name, uri, resource_id, account_id, params)

      [payload, request]
    end

    def generate_signature_payload(resource_id)
      if resource_id
        { id: resource_id }.to_json
      else
        '{}'
      end
    end

    def generate_request(method_name, uri, account_id)
      append_request_headers(account_id: account_id) do
        case method_name
        when :get   then Net::HTTP::Get.new(uri.request_uri)
        when :post  then Net::HTTP::Post.new(uri.request_uri)
        when :put   then Net::HTTP::Put.new(uri.request_uri)
        when :patch then Net::HTTP::Patch.new(uri.request_uri)
        else
          raise ArgumentError, "Unsupported HTTP method: #{method_name}"
        end
      end
    end

    def generate_signature_request(method_name, uri, resource_id, account_id, params)
      return nil unless resource_id

      params = {} if params.nil?
      params[:sig_payload] = { id: resource_id }.to_json

      # Update the URI with the new params
      uri.query = URI.encode_www_form(params)

      append_request_headers(account_id: account_id) do
        case method_name
        when :get   then Net::HTTP::Get.new(uri.request_uri)
        when :post  then Net::HTTP::Post.new(uri.request_uri)
        end
      end
    end

    def generate_signature(payload)
      # Base64 encode the payload
      encoded_payload = Base64.strict_encode64(payload.to_s)

      # Generate SHA256 hash
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), api_secret, encoded_payload)
    end

    def generate_resource_id(method_name, body, path)
      return unless method_name == :get || (method_name == :post && (body.nil? || body.empty?))

      parts = path.strip.split('/')
      return unless parts.length >= 2

      if %w[suspend resume unlink delete].include?(parts.last)
        parts[-2]
      else
        parts.last
      end
    end

    def append_request_headers(account_id:, &block)
      block.call.tap do |request|
        request['Content-Type'] = 'application/json'
        request['X-ACCT-ID'] = account_id
        request['User-Agent'] = "accessgrid.rb @ v#{AccessGrid::VERSION}"
      end
    end
  end

  def self.new(account_id, api_secret, api_host = 'https://api.accessgrid.com')
    Client.new(account_id, api_secret, api_host)
  end
end
