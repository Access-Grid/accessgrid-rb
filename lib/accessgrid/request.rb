# frozen_string_literal: true

require 'uri'

module AccessGrid
  class Request
    PAYLOAD_SIGNATURE_PARAM = :sig_payload

    attr_reader :account_id, :body, :http_method, :params, :payload, :uri

    def initialize(attrs)
      # required attributes
      @http_method = attrs.fetch(:http_method)
      @host = attrs.fetch(:host)
      @path = attrs.fetch(:path)

      # optional attributes
      @account_id = attrs.fetch(:account_id, nil)
      @body = attrs.fetch(:body, nil)
      @params = attrs.fetch(:params, nil) || {}

      # computed attributes
      initialize_payload
      initialize_uri
    end

    def net_http_request
      return @net_http_request if defined?(@net_http_request)

      @net_http_request = generate_net_http_request!.tap do |req|
        req['Content-Type'] = 'application/json'
        req['X-ACCT-ID'] = account_id
        req['User-Agent'] = "accessgrid.rb @ v#{AccessGrid::VERSION}"

        req.body = body.to_json if body && !get?
      end
    end

    private

    def generate_net_http_request!
      case http_method
      when :get   then  Net::HTTP::Get.new(uri.request_uri)
      when :post  then  Net::HTTP::Post.new(uri.request_uri)
      when :put   then  Net::HTTP::Put.new(uri.request_uri)
      when :patch then  Net::HTTP::Patch.new(uri.request_uri)
      else
        raise ArgumentError, "Unsupported HTTP method: #{http_method}"
      end
    end

    def initialize_payload
      return @payload if defined?(@payload)
      return @payload = default_payload unless post_without_body_or_get?

      if resource_id
        @payload = { id: resource_id }.to_json
        @params[PAYLOAD_SIGNATURE_PARAM] = @payload
      else
        @payload = '{}'
      end

      @payload
    end

    def initialize_uri
      @uri = URI.parse("#{@host}#{@path}").tap do |u|
        u.query = URI.encode_www_form(@params) if @params.any?
      end
    end

    def resource_id
      return @resource_id if defined?(@resource_id)
      return @resource_id = nil unless post_without_body_or_get?

      parts = @path.strip.split('/')
      return @resource_id = nil unless parts.length >= 2

      @resource_id = %w[suspend resume unlink delete].include?(parts.last) ? parts[-2] : parts.last
    end

    def get?
      http_method == :get
    end

    def post?
      http_method == :post
    end

    def empty_body?
      body.nil? || body.empty?
    end

    def post_without_body_or_get?
      get? || (post? && empty_body?)
    end

    def default_payload
      body&.to_json || ''
    end
  end
end
