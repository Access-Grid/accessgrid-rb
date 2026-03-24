# frozen_string_literal: true

# lib/accessgrid.rb
require 'base64'
require 'json'
require 'net/http'
require 'openssl'
require 'uri'

require_relative 'accessgrid/access_cards'
require_relative 'accessgrid/console'
require_relative 'accessgrid/error'
require_relative 'accessgrid/request'
require_relative 'accessgrid/version'

# Ruby SDK for the AccessGrid API.
module AccessGrid
  # API client for AccessGrid key card and template management.
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
      request = Request.new(
        account_id: account_id,
        body: body,
        host: api_host,
        http_method: method,
        params: params,
        path: path
      )

      execute_and_process_request!(request)
    end

    private

    def execute_and_process_request!(request)
      # set up net http
      uri = request.uri
      http = Net::HTTP.new(uri.host, uri.port).tap { |http| http.use_ssl = uri.scheme == 'https' }

      # Generate signature
      net_http_request = request.net_http_request
      net_http_request['X-PAYLOAD-SIG'] = generate_signature_hash(request.payload)

      # Make request
      response = http.request(net_http_request)

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
      body = response.body
      error_message = body.empty? ? "HTTP Status #{response.code}" : body

      begin
        error_data = JSON.parse(body)
        error_message = error_data['message'] if error_data['message']
      rescue JSON::ParserError
        # If it's not valid JSON, just use the response body
      end

      raise Error, "API request failed: #{error_message}"
    end

    def generate_signature_hash(value)
      # Base64 encode the value
      encoded_value = Base64.strict_encode64(value.to_s)

      # Generate SHA256 hash
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), api_secret, encoded_value)
    end
  end

  def self.new(account_id, api_secret, api_host = 'https://api.accessgrid.com')
    Client.new(account_id, api_secret, api_host)
  end
end
