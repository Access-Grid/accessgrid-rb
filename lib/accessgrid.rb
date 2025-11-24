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
    attr_reader :account_id, :api_secret, :api_host
    
    def initialize(account_id, api_secret, api_host = 'https://api.accessgrid.com')
      if account_id.nil? || account_id.empty?
        raise ArgumentError, "Account ID is required"
      end
      
      if api_secret.nil? || api_secret.empty?
        raise ArgumentError, "API Secret is required"
      end
      
      @account_id = account_id
      @api_secret = api_secret
      @api_host = api_host.chomp('/')
    end

    def access_cards
      @access_cards ||= AccessCards.new(self)
    end

    def console
      @console ||= Console.new(self)
    end

    def make_request(method, path, body = nil, params = nil)
      uri = URI.parse("#{api_host}#{path}")
      
      # Add query parameters if present
      if params && !params.empty?
        uri.query = URI.encode_www_form(params)
      end
      
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
      when :patch
        Net::HTTP::Patch.new(uri.request_uri)
      else
        raise ArgumentError, "Unsupported HTTP method: #{method}"
      end

      # Set headers
      request['Content-Type'] = 'application/json'
      request['X-ACCT-ID'] = account_id
      request['User-Agent'] = "accessgrid.rb @ v#{AccessGrid::VERSION}"
      
      # Extract resource ID from the path if needed for signature
      resource_id = nil
      if method == :get || (method == :post && (body.nil? || body.empty?))
        parts = path.strip.split('/')
        if parts.length >= 2
          if ['suspend', 'resume', 'unlink', 'delete'].include?(parts.last)
            resource_id = parts[-2]
          else
            resource_id = parts.last
          end
        end
      end
      
      # Handle signature generation
      if method == :get || (method == :post && (body.nil? || body.empty?))
        payload = resource_id ? { id: resource_id }.to_json : '{}'
        
        # Include sig_payload in query params if needed
        if resource_id
          if params.nil?
            params = {}
          end
          params[:sig_payload] = { id: resource_id }.to_json
          
          # Update the URI with the new params
          uri.query = URI.encode_www_form(params)
          request = case method
          when :get
            Net::HTTP::Get.new(uri.request_uri)
          when :post
            Net::HTTP::Post.new(uri.request_uri)
          end
          
          # Reset headers after creating new request
          request['Content-Type'] = 'application/json'
          request['X-ACCT-ID'] = account_id
          request['User-Agent'] = "accessgrid.rb @ v#{AccessGrid::VERSION}"
        end
      else
        payload = body ? body.to_json : ""
      end
      
      # Generate signature
      request['X-PAYLOAD-SIG'] = generate_signature(payload)
      
      # Add the body to the request
      if body && method != :get
        request.body = body.to_json
      end

      # Make request
      response = http.request(request)
      
      # Parse response
      handle_response(response)
    end

    private

    def generate_signature(payload)
      # Base64 encode the payload
      encoded_payload = Base64.strict_encode64(payload.to_s)
      
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
      when 402
        raise Error, 'Insufficient account balance'
      when 404
        raise ResourceNotFoundError, 'Resource not found'
      when 422
        raise ValidationError, JSON.parse(response.body)['message']
      else
        error_message = response.body.empty? ? "HTTP Status #{response.code}" : response.body
        begin
          error_data = JSON.parse(response.body)
          error_message = error_data['message'] if error_data['message']
        rescue JSON::ParserError
          # If it's not valid JSON, just use the response body
        end
        raise Error, "API request failed: #{error_message}"
      end
    end
  end

  def self.new(account_id, api_secret, api_host = 'https://api.accessgrid.com')
    Client.new(account_id, api_secret, api_host)
  end
end