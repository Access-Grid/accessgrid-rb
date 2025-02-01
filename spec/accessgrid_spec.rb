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
  end

  describe '#generate_signature' do
    it 'generates correct HMAC signature' do
      payload = { test: 'data' }.to_json
      signature = client.send(:generate_signature, payload)
      expect(signature).to be_a(String)
      expect(signature.length).to eq(64) # SHA256 hex digest length
    end
  end
end