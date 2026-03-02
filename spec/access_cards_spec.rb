# frozen_string_literal: true

require 'spec_helper'

# spec/access_cards_spec.rb
RSpec.describe AccessGrid::AccessCards do
  let(:client) { AccessGrid.new('test_account', 'test_secret') }
  let(:cards) { client.access_cards }

  describe '#issue' do
    let(:issue_params) do
      {
        card_template_id: 'template_123',
        employee_id: '123456',
        full_name: 'Jane Doe',
        email: 'jane@example.com'
      }
    end

    let(:success_response) do
      {
        id: 'card_456',
        install_url: 'https://install.url/456',
        state: 'pending',
        full_name: 'Jane Doe'
      }
    end

    it 'creates a new access card (issue is the canonical method)' do
      stub_api_request(:post, '/v1/key-cards', body: success_response, request_body: issue_params)

      card = cards.issue(issue_params)

      expect(card).to be_a(AccessGrid::Card)
      expect(card.id).to eq('card_456')
      expect(card.state).to eq('pending')
    end
  end

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
      stub_api_request(:post, '/v1/key-cards', body: success_response, request_body: provision_params)

      card = cards.provision(provision_params)

      expect(card).to be_a(AccessGrid::Card)
      expect(card.id).to eq('card_123')
      expect(card.url).to eq('https://install.url')
      expect(card.state).to eq('active')
    end

    it 'handles validation errors' do
      error_response = { status: 'error', message: 'Invalid parameters' }
      stub_api_request(:post, '/v1/key-cards', status: 422, body: error_response, request_body: provision_params)

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

      stub_api_request(:patch, '/v1/key-cards/card_123', body: success_response, request_body: update_params)

      card = cards.update('card_123', update_params)

      expect(card.full_name).to eq('Updated Name')
    end
  end

  describe '#get' do
    let(:card_response) do
      {
        id: 'card_789',
        state: 'active',
        install_url: 'https://install.url/789',
        full_name: 'Bob Smith',
        expiration_date: '2025-12-31T00:00:00Z',
        card_number: '12345',
        site_code: 'SC001',
        devices: [{ type: 'iphone', id: 'device_1' }],
        metadata: { department: 'Engineering' }
      }
    end

    it 'retrieves a card by id' do
      stub_api_request(
        :get,
        '/v1/key-cards/card_789',
        body: card_response,
        query: generate_sig_payload(id: :card_789)
      )

      card = cards.get(card_id: 'card_789')

      expect(card).to be_a(AccessGrid::Card)
      expect(card.id).to eq('card_789')
      expect(card.state).to eq('active')
      expect(card.full_name).to eq('Bob Smith')
      expect(card.card_number).to eq('12345')
      expect(card.site_code).to eq('SC001')
      expect(card.devices).to eq([{ 'type' => 'iphone', 'id' => 'device_1' }])
      expect(card.metadata).to eq({ 'department' => 'Engineering' })
    end
  end

  describe '#list' do
    let(:list_response) do
      {
        keys: [
          { id: 'card_1', state: 'active', full_name: 'User One' },
          { id: 'card_2', state: 'suspended', full_name: 'User Two' }
        ]
      }
    end

    it 'lists cards for a template' do
      stub_api_request(
        :get,
        '/v1/key-cards',
        body: list_response,
        query: { template_id: 'tmpl_123', sig_payload: '{"id":"key-cards"}' }
      )

      result = cards.list('tmpl_123')

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first).to be_a(AccessGrid::Card)
      expect(result.first.id).to eq('card_1')
      expect(result.last.id).to eq('card_2')
    end

    it 'lists cards filtered by state' do
      filtered_response = { keys: [{ id: 'card_1', state: 'active', full_name: 'User One' }] }

      stub_api_request(
        :get,
        '/v1/key-cards',
        body: filtered_response,
        query: { template_id: 'tmpl_123', state: 'active', sig_payload: '{"id":"key-cards"}' }
      )

      result = cards.list('tmpl_123', 'active')

      expect(result.length).to eq(1)
      expect(result.first.state).to eq('active')
    end

    it 'returns empty array when no cards found' do
      stub_api_request(
        :get,
        '/v1/key-cards',
        body: { keys: [] },
        query: { template_id: 'tmpl_empty', sig_payload: '{"id":"key-cards"}' }
      )

      result = cards.list('tmpl_empty')

      expect(result).to eq([])
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
        body: state_response,
        query: generate_sig_payload(id: :card_123)
      )

      card = cards.suspend('card_123')
      expect(card.state).to eq('suspended')
    end

    it 'resumes a card' do
      response = state_response.merge(state: 'active')
      stub_api_request(
        :post,
        '/v1/key-cards/card_123/resume',
        body: response,
        query: generate_sig_payload(id: :card_123)
      )

      card = cards.resume('card_123')
      expect(card.state).to eq('active')
    end

    it 'unlinks a card' do
      response = state_response.merge(state: 'unlinked')
      stub_api_request(
        :post,
        '/v1/key-cards/card_123/unlink',
        body: response,
        query: generate_sig_payload(id: :card_123)
      )

      card = cards.unlink('card_123')
      expect(card.state).to eq('unlinked')
    end

    it 'deletes a card' do
      response = state_response.merge(state: 'deleted')
      stub_api_request(
        :post,
        '/v1/key-cards/card_123/delete',
        body: response,
        query: generate_sig_payload(id: :card_123)
      )

      card = cards.delete('card_123')
      expect(card.state).to eq('deleted')
    end
  end
end
