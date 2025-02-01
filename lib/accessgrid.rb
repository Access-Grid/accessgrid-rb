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
  
  class Client
    attr_reader :account_id, :api_secret, :api_host
    
    def initialize(account_id, api_secret, api_host = 'https://api.accessgrid.com')
      @account_id = account_id
      @api_secret = api_secret
      @api_host = api_host
    end

    def access_cards
      @access_cards ||= AccessCards.new(self)
    end

    def console
      @console ||= Console.new(self)
    end

    def make_request(method, path, body = nil)
      uri = URI.parse("#{api_host}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'

      # Create request object based on method
      request = case method
      when :get
        Net::HTTP::Get.new(uri.request_uri)
      when :post
        Net::HTTP::Post.new(uri.request_uri)
      when :put
        Net::HTTP::Put.new(uri.request_uri)
      else
        raise ArgumentError, "Unsupported HTTP method: #{method}"
      end

      # Set headers
      request['Content-Type'] = 'application/json'
      request['X-ACCT-ID'] = account_id
      
      # Generate signature if body present
      if body
        json_body = body.to_json
        request['X-PAYLOAD-SIG'] = generate_signature(json_body)
        request.body = json_body
      end

      # Make request
      response = http.request(request)
      
      # Parse response
      handle_response(response)
    end

    private

    def generate_signature(payload)
      # Base64 encode the payload
      encoded_payload = Base64.strict_encode64(payload)
      
      # Generate SHA256 hash
      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('sha256'),
        api_secret,
        encoded_payload
      )
    end

    def handle_response(response)
      case response.code.to_i
      when 200, 201, 202
        JSON.parse(response.body)
      when 401
        raise AuthenticationError, 'Invalid credentials'
      when 404
        raise ResourceNotFoundError, 'Resource not found'
      when 422
        raise ValidationError, JSON.parse(response.body)['message']
      else
        raise Error, "API request failed with status #{response.code}: #{response.body}"
      end
    end
  end

  def self.new(account_id, api_secret, api_host = 'https://api.accessgrid.com')
    Client.new(account_id, api_secret, api_host)
  end
end