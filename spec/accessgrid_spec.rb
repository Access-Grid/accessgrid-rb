# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessGrid do
  let(:client) { AccessGrid.new('test_account', 'test_secret') }

  describe '#initialize' do
    it 'creates a new client with account_id and api_secret' do
      expect(client.account_id).to eq('test_account')
      expect(client.api_secret).to eq('test_secret')
      expect(client.api_host).to eq('https://api.accessgrid.com')
    end

    it 'allows custom api host' do
      custom_client = AccessGrid.new('test_account', 'test_secret', 'https://custom.host')
      expect(custom_client.api_host).to eq('https://custom.host')
    end

    it 'strips trailing slash from api host' do
      custom_client = AccessGrid.new('test_account', 'test_secret', 'https://custom.host/')
      expect(custom_client.api_host).to eq('https://custom.host')
    end

    context 'with invalid account_id' do
      it 'raises ArgumentError when nil' do
        expect { AccessGrid.new(nil, 'test_secret') }
          .to raise_error(ArgumentError, 'Account ID is required')
      end

      it 'raises ArgumentError when empty string' do
        expect { AccessGrid.new('', 'test_secret') }
          .to raise_error(ArgumentError, 'Account ID is required')
      end
    end

    context 'with invalid api_secret' do
      it 'raises ArgumentError when nil' do
        expect { AccessGrid.new('test_account', nil) }
          .to raise_error(ArgumentError, 'API Secret is required')
      end

      it 'raises ArgumentError when empty string' do
        expect { AccessGrid.new('test_account', '') }
          .to raise_error(ArgumentError, 'API Secret is required')
      end
    end
  end

  describe '#generate_signature' do
    it 'generates correct HMAC signature' do
      payload = { test: 'data' }.to_json
      signature = client.send(:generate_signature_hash, payload)
      expect(signature).to be_a(String)
      expect(signature.length).to eq(64) # SHA256 hex digest length
    end
  end

  describe 'error handling' do
    describe '401 Unauthorized' do
      it 'raises AuthenticationError' do
        stub_api_request(:get, '/v1/key-cards/card_123', status: 401, body: {},
                                                         query: generate_sig_payload(id: :card_123))

        expect { client.access_cards.get(card_id: 'card_123') }
          .to raise_error(AccessGrid::AuthenticationError, 'Invalid credentials')
      end
    end

    describe '402 Payment Required' do
      it 'raises Error with insufficient balance message' do
        stub_api_request(:get, '/v1/key-cards/card_123', status: 402, body: {},
                                                         query: generate_sig_payload(id: :card_123))

        expect { client.access_cards.get(card_id: 'card_123') }
          .to raise_error(AccessGrid::Error, 'Insufficient account balance')
      end
    end

    describe '404 Not Found' do
      it 'raises ResourceNotFoundError' do
        stub_api_request(:get, '/v1/key-cards/card_123', status: 404, body: {},
                                                         query: generate_sig_payload(id: :card_123))

        expect { client.access_cards.get(card_id: 'card_123') }
          .to raise_error(AccessGrid::ResourceNotFoundError, 'Resource not found')
      end
    end

    describe '422 Unprocessable Entity' do
      it 'raises ValidationError with message from response' do
        error_body = { message: 'Invalid card_template_id' }
        stub_api_request(:post, '/v1/key-cards', status: 422, body: error_body)

        expect { client.access_cards.issue(card_template_id: 'invalid') }
          .to raise_error(AccessGrid::ValidationError, 'Invalid card_template_id')
      end
    end

    describe 'unhandled status codes' do
      it 'raises Error with status code when body is empty' do
        query_string = URI.encode_www_form(generate_sig_payload(id: :card_123))
        stub_request(:get, "https://api.accessgrid.com/v1/key-cards/card_123?#{query_string}")
          .with(headers: { 'Content-Type' => 'application/json', 'X-ACCT-ID' => 'test_account' })
          .to_return(status: 500, body: '', headers: {})

        expect { client.access_cards.get(card_id: 'card_123') }
          .to raise_error(AccessGrid::Error, 'API request failed: HTTP Status 500')
      end

      it 'raises Error with message from JSON response' do
        error_body = { message: 'Internal server error' }
        stub_api_request(:get, '/v1/key-cards/card_123', status: 500, body: error_body,
                                                         query: generate_sig_payload(id: :card_123))

        expect { client.access_cards.get(card_id: 'card_123') }
          .to raise_error(AccessGrid::Error, 'API request failed: Internal server error')
      end

      it 'raises Error with raw body when response is not JSON' do
        query_string = URI.encode_www_form(generate_sig_payload(id: :card_123))
        stub_request(:get, "https://api.accessgrid.com/v1/key-cards/card_123?#{query_string}")
          .with(headers: { 'Content-Type' => 'application/json', 'X-ACCT-ID' => 'test_account' })
          .to_return(status: 503, body: 'Service Unavailable', headers: {})

        expect { client.access_cards.get(card_id: 'card_123') }
          .to raise_error(AccessGrid::Error, 'API request failed: Service Unavailable')
      end
    end
  end
end
