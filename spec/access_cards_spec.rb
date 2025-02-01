# spec/access_cards_spec.rb
RSpec.describe AccessGrid::AccessCards do
  let(:client) { AccessGrid.new('test_account', 'test_secret') }
  let(:cards) { client.access_cards }

  describe '#provision' do
    let(:provision_params) do
      {
        card_template_id: 'template_123',
        employee_id: '123456',
        full_name: 'John Doe',
        email: 'john@example.com'
      }
    end

    let(:success_response) do
      {
        status: 'success',
        id: 'card_123',
        install_url: 'https://install.url',
        state: 'active',
        full_name: 'John Doe',
        expiration_date: '2025-01-01T00:00:00Z'
      }
    end

    it 'creates a new access card' do
      stub_api_request(:post, '/api/v1/nfc_keys/issue', body: success_response)
      
      card = cards.provision(provision_params)
      
      expect(card).to be_a(AccessGrid::Card)
      expect(card.id).to eq('card_123')
      expect(card.url).to eq('https://install.url')
      expect(card.state).to eq('active')
    end

    it 'handles validation errors' do
      error_response = { status: 'error', message: 'Invalid parameters' }
      stub_api_request(:post, '/api/v1/nfc_keys/issue', status: 422, body: error_response)
      
      expect { cards.provision(provision_params) }
        .to raise_error(AccessGrid::ValidationError, 'Invalid parameters')
    end
  end

  describe '#update' do
    let(:update_params) do
      {
        card_id: 'card_123',
        full_name: 'Updated Name',
        employee_id: '789012'
      }
    end

    it 'updates an existing card' do
      success_response = {
        status: 'success',
        id: 'card_123',
        install_url: 'https://install.url',
        state: 'active',
        full_name: 'Updated Name'
      }

      stub_api_request(:put, '/api/v1/nfc_keys/card_123', body: success_response)
      
      card = cards.update(update_params)
      
      expect(card.full_name).to eq('Updated Name')
    end
  end

  describe 'state management' do
    let(:state_response) do
      {
        status: 'success',
        id: 'card_123',
        state: 'suspended',
        install_url: 'https://install.url'
      }
    end

    it 'suspends a card' do
      stub_api_request(
        :post, 
        '/api/v1/nfc_keys/card_123/manage',
        body: state_response
      )
      
      card = cards.suspend(card_id: 'card_123')
      expect(card.state).to eq('suspended')
    end

    it 'resumes a card' do
      response = state_response.merge(state: 'active')
      stub_api_request(
        :post, 
        '/api/v1/nfc_keys/card_123/manage',
        body: response
      )
      
      card = cards.resume(card_id: 'card_123')
      expect(card.state).to eq('active')
    end
  end
end