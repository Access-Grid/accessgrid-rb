# spec/access_cards_spec.rb
RSpec.describe AccessGrid::Union do
  describe '.from_response' do
    it 'returns a Card when details is nil' do
      data = { 'id' => 'card_123', 'state' => 'active', 'install_url' => 'https://example.com' }
      result = described_class.from_response(data)

      expect(result).to be_a(AccessGrid::Card)
      expect(result.card?).to be true
      expect(result.unified_access_pass?).to be false
    end

    it 'returns a Card when details is empty array' do
      data = { 'id' => 'card_123', 'state' => 'active', 'details' => [] }
      result = described_class.from_response(data)

      expect(result).to be_a(AccessGrid::Card)
    end

    it 'returns a UnifiedAccessPass when details has cards' do
      data = {
        'id' => 'TP-xxx',
        'state' => 'created',
        'status' => 'success',
        'install_url' => 'https://example.com',
        'details' => [
          { 'id' => 'card1', 'state' => 'active', 'full_name' => 'Apple Card' },
          { 'id' => 'card2', 'state' => 'active', 'full_name' => 'Android Card' }
        ]
      }
      result = described_class.from_response(data)

      expect(result).to be_a(AccessGrid::UnifiedAccessPass)
      expect(result.unified_access_pass?).to be true
      expect(result.card?).to be false
      expect(result.id).to eq('TP-xxx')
      expect(result.status).to eq('success')
      expect(result.details.length).to eq(2)
      expect(result.details.first).to be_a(AccessGrid::Card)
      expect(result.details.first.full_name).to eq('Apple Card')
    end
  end
end

RSpec.describe AccessGrid::UnifiedAccessPass do
  let(:data) do
    {
      'id' => 'TP-123',
      'state' => 'created',
      'status' => 'success',
      'install_url' => 'https://install.example.com',
      'details' => [
        { 'id' => 'card1', 'state' => 'active', 'full_name' => 'Card One', 'card_template_id' => 'tmpl_apple' },
        { 'id' => 'card2', 'state' => 'active', 'full_name' => 'Card Two', 'card_template_id' => 'tmpl_android' }
      ]
    }
  end

  subject { described_class.new(data) }

  it 'inherits common properties from Union' do
    expect(subject.id).to eq('TP-123')
    expect(subject.state).to eq('created')
    expect(subject.url).to eq('https://install.example.com')
  end

  it 'has status property' do
    expect(subject.status).to eq('success')
  end

  it 'parses details as Card objects' do
    expect(subject.details.length).to eq(2)
    expect(subject.details).to all(be_a(AccessGrid::Card))
  end

  it 'provides access to nested card properties' do
    apple_card = subject.details.first
    expect(apple_card.id).to eq('card1')
    expect(apple_card.full_name).to eq('Card One')
    expect(apple_card.card_template_id).to eq('tmpl_apple')
  end

  it 'returns correct type check' do
    expect(subject.unified_access_pass?).to be true
    expect(subject.card?).to be false
  end

  it 'has a readable to_s representation' do
    expect(subject.to_s).to eq("UnifiedAccessPass(id='TP-123', state='created', status='success', cards=2)")
  end
end

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
      stub_api_request(:post, '/v1/key-cards', body: success_response)

      card = cards.provision(provision_params)

      expect(card).to be_a(AccessGrid::Card)
      expect(card.id).to eq('card_123')
      expect(card.url).to eq('https://install.url')
      expect(card.state).to eq('active')
    end

    it 'handles validation errors' do
      error_response = { status: 'error', message: 'Invalid parameters' }
      stub_api_request(:post, '/v1/key-cards', status: 422, body: error_response)

      expect { cards.provision(provision_params) }
        .to raise_error(AccessGrid::ValidationError, 'Invalid parameters')
    end

    it 'returns UnifiedAccessPass when response has details array' do
      unified_response = {
        id: 'TP-123',
        install_url: 'https://install.url',
        state: 'created',
        status: 'success',
        details: [
          { id: 'card_1', state: 'active', full_name: 'John Doe' },
          { id: 'card_2', state: 'active', full_name: 'John Doe' }
        ]
      }
      stub_api_request(:post, '/v1/key-cards', body: unified_response)

      result = cards.provision(provision_params)

      expect(result).to be_a(AccessGrid::UnifiedAccessPass)
      expect(result.unified_access_pass?).to be true
      expect(result.details.length).to eq(2)
    end
  end

  describe '#update' do
    let(:update_params) do
      {
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

      stub_api_request(:patch, '/v1/key-cards/card_123', body: success_response)

      card = cards.update('card_123', update_params)

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
        '/v1/key-cards/card_123/suspend',
        body: state_response
      )

      card = cards.suspend('card_123')
      expect(card.state).to eq('suspended')
    end

    it 'resumes a card' do
      response = state_response.merge(state: 'active')
      stub_api_request(
        :post,
        '/v1/key-cards/card_123/resume',
        body: response
      )

      card = cards.resume('card_123')
      expect(card.state).to eq('active')
    end
  end
end