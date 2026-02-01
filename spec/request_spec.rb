# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessGrid::Request do
  let(:default_attrs) do
    {
      http_method: :get,
      host: 'https://api.accessgrid.com',
      path: '/v1/key-cards',
      account_id: 'test_account'
    }
  end

  def build_request(overrides = {})
    described_class.new(default_attrs.merge(overrides))
  end

  describe '#initialize' do
    context 'with required attributes' do
      it 'creates a request with http_method, host, and path' do
        request = build_request

        expect(request.http_method).to eq(:get)
        expect(request.uri.to_s).to start_with('https://api.accessgrid.com/v1/key-cards')
      end
    end

    context 'with optional attributes' do
      it 'accepts account_id' do
        request = build_request(account_id: 'my_account')
        expect(request.account_id).to eq('my_account')
      end

      it 'accepts body' do
        body = { name: 'Test' }
        request = build_request(http_method: :post, body: body)
        expect(request.body).to eq(body)
      end

      it 'accepts params' do
        request = build_request(params: { state: 'active' })
        expect(request.params).to include(state: 'active')
      end

      it 'defaults params to empty hash when nil' do
        request = build_request(params: nil)
        expect(request.params).to be_a(Hash)
      end
    end

    context 'with missing required attributes' do
      it 'raises KeyError when http_method is missing' do
        expect { described_class.new(host: 'https://example.com', path: '/test') }
          .to raise_error(KeyError, /http_method/)
      end

      it 'raises KeyError when host is missing' do
        expect { described_class.new(http_method: :get, path: '/test') }
          .to raise_error(KeyError, /host/)
      end

      it 'raises KeyError when path is missing' do
        expect { described_class.new(http_method: :get, host: 'https://example.com') }
          .to raise_error(KeyError, /path/)
      end
    end
  end

  describe 'URI construction' do
    it 'builds URI from host and path' do
      request = build_request(
        host: 'https://api.example.com',
        path: '/v1/resources'
      )

      expect(request.uri.host).to eq('api.example.com')
      expect(request.uri.path).to eq('/v1/resources')
    end

    it 'encodes query params into URI' do
      request = build_request(
        http_method: :post,
        body: { name: 'Test' },
        params: { filter: 'active', page: 1 }
      )

      expect(request.uri.query).to include('filter=active')
      expect(request.uri.query).to include('page=1')
    end

    it 'handles empty params without query string' do
      request = build_request(
        http_method: :post,
        body: { name: 'Test' },
        params: {}
      )

      expect(request.uri.query).to be_nil
    end

    describe '#host' do
      it 'returns the URI host' do
        request = build_request(host: 'https://custom.host.com')
        expect(request.host).to eq('custom.host.com')
      end
    end

    describe '#port' do
      it 'returns 443 for https' do
        request = build_request(host: 'https://api.example.com')
        expect(request.port).to eq(443)
      end

      it 'returns 80 for http' do
        request = build_request(host: 'http://api.example.com')
        expect(request.port).to eq(80)
      end
    end

    describe '#use_ssl?' do
      it 'returns true for https' do
        request = build_request(host: 'https://api.example.com')
        expect(request.use_ssl?).to be true
      end

      it 'returns false for http' do
        request = build_request(host: 'http://api.example.com')
        expect(request.use_ssl?).to be false
      end
    end
  end

  describe 'payload generation' do
    context 'POST request with body' do
      it 'uses body as payload' do
        body = { card_template_id: 'tmpl_123', full_name: 'John Doe' }
        request = build_request(http_method: :post, body: body)

        expect(request.payload).to eq(body.to_json)
      end

      it 'does not add sig_payload to params' do
        body = { card_template_id: 'tmpl_123' }
        request = build_request(http_method: :post, body: body, params: {})

        expect(request.params).not_to have_key(:sig_payload)
      end
    end

    context 'POST request without body' do
      it 'extracts resource_id and builds payload' do
        request = build_request(
          http_method: :post,
          path: '/v1/key-cards/card_123/suspend',
          body: nil
        )

        expect(request.payload).to eq({ id: 'card_123' }.to_json)
      end

      it 'adds sig_payload to params' do
        request = build_request(
          http_method: :post,
          path: '/v1/key-cards/card_123/suspend',
          body: nil
        )

        expect(request.params[:sig_payload]).to eq({ id: 'card_123' }.to_json)
      end
    end

    context 'POST request with empty body' do
      it 'treats empty hash as empty body' do
        request = build_request(
          http_method: :post,
          path: '/v1/key-cards/card_123/suspend',
          body: {}
        )

        expect(request.payload).to eq({ id: 'card_123' }.to_json)
        expect(request.params[:sig_payload]).to eq({ id: 'card_123' }.to_json)
      end
    end

    context 'GET request' do
      it 'extracts resource_id and builds payload' do
        request = build_request(
          http_method: :get,
          path: '/v1/key-cards/card_456'
        )

        expect(request.payload).to eq({ id: 'card_456' }.to_json)
      end

      it 'adds sig_payload to params' do
        request = build_request(
          http_method: :get,
          path: '/v1/key-cards/card_456'
        )

        expect(request.params[:sig_payload]).to eq({ id: 'card_456' }.to_json)
      end

      it 'uses empty JSON object when no resource_id' do
        request = build_request(
          http_method: :get,
          path: '/'
        )

        expect(request.payload).to eq('{}')
      end
    end

    context 'PUT request' do
      it 'uses body as payload' do
        body = { name: 'Updated Name' }
        request = build_request(http_method: :put, body: body)

        expect(request.payload).to eq(body.to_json)
      end
    end

    context 'PATCH request' do
      it 'uses body as payload' do
        body = { name: 'Patched Name' }
        request = build_request(http_method: :patch, body: body)

        expect(request.payload).to eq(body.to_json)
      end
    end
  end

  describe 'resource_id extraction' do
    it 'extracts ID from standard resource path' do
      request = build_request(path: '/v1/key-cards/card_123')
      expect(request.send(:resource_id)).to eq('card_123')
    end

    it 'extracts ID from action path (suspend)' do
      request = build_request(path: '/v1/key-cards/card_123/suspend')
      expect(request.send(:resource_id)).to eq('card_123')
    end

    it 'extracts ID from action path (resume)' do
      request = build_request(path: '/v1/key-cards/card_123/resume')
      expect(request.send(:resource_id)).to eq('card_123')
    end

    it 'extracts ID from action path (unlink)' do
      request = build_request(path: '/v1/key-cards/card_123/unlink')
      expect(request.send(:resource_id)).to eq('card_123')
    end

    it 'extracts ID from action path (delete)' do
      request = build_request(path: '/v1/key-cards/card_123/delete')
      expect(request.send(:resource_id)).to eq('card_123')
    end

    it 'returns nil for root path' do
      request = build_request(path: '/')
      expect(request.send(:resource_id)).to be_nil
    end

    it 'extracts last segment for non-action paths' do
      request = build_request(path: '/v1/console/card-templates/tmpl_456')
      expect(request.send(:resource_id)).to eq('tmpl_456')
    end
  end

  describe '#net_http_request' do
    it 'returns Net::HTTP::Get for :get method' do
      request = build_request(http_method: :get)
      expect(request.net_http_request).to be_a(Net::HTTP::Get)
    end

    it 'returns Net::HTTP::Post for :post method' do
      request = build_request(http_method: :post, body: { test: true })
      expect(request.net_http_request).to be_a(Net::HTTP::Post)
    end

    it 'returns Net::HTTP::Put for :put method' do
      request = build_request(http_method: :put, body: { test: true })
      expect(request.net_http_request).to be_a(Net::HTTP::Put)
    end

    it 'returns Net::HTTP::Patch for :patch method' do
      request = build_request(http_method: :patch, body: { test: true })
      expect(request.net_http_request).to be_a(Net::HTTP::Patch)
    end

    it 'raises ArgumentError for unsupported HTTP method' do
      request = build_request(http_method: :delete)
      expect { request.net_http_request }.to raise_error(ArgumentError, /Unsupported HTTP method/)
    end

    describe 'headers' do
      it 'sets Content-Type header' do
        request = build_request
        expect(request.net_http_request['Content-Type']).to eq('application/json')
      end

      it 'sets X-ACCT-ID header' do
        request = build_request(account_id: 'my_account_123')
        expect(request.net_http_request['X-ACCT-ID']).to eq('my_account_123')
      end

      it 'sets User-Agent header with version' do
        request = build_request
        expect(request.net_http_request['User-Agent']).to eq("accessgrid.rb @ v#{AccessGrid::VERSION}")
      end
    end

    describe 'body' do
      it 'sets body for POST requests' do
        body = { name: 'Test' }
        request = build_request(http_method: :post, body: body)

        expect(request.net_http_request.body).to eq(body.to_json)
      end

      it 'sets body for PUT requests' do
        body = { name: 'Test' }
        request = build_request(http_method: :put, body: body)

        expect(request.net_http_request.body).to eq(body.to_json)
      end

      it 'sets body for PATCH requests' do
        body = { name: 'Test' }
        request = build_request(http_method: :patch, body: body)

        expect(request.net_http_request.body).to eq(body.to_json)
      end

      it 'does not set body for GET requests' do
        request = build_request(http_method: :get, body: { ignored: true })

        expect(request.net_http_request.body).to be_nil
      end
    end

    it 'memoizes the request object' do
      request = build_request
      first_call = request.net_http_request
      second_call = request.net_http_request

      expect(first_call).to be(second_call)
    end
  end
end
