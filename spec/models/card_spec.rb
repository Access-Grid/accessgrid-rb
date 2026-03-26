# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessGrid::Card do
  describe '#initialize' do
    context 'with complete data' do
      let(:data) do
        {
          'id' => 'card_123',
          'state' => 'active',
          'install_url' => 'https://install.example.com/abc',
          'details' => { 'extra' => 'info' },
          'full_name' => 'John Doe',
          'expiration_date' => '2025-12-31T00:00:00Z',
          'card_template_id' => 'tmpl_456',
          'card_number' => '98765',
          'site_code' => 'SC100',
          'file_data' => 'base64encodeddata',
          'direct_install_url' => 'https://direct.example.com/xyz',
          'devices' => [
            { 'type' => 'iphone', 'id' => 'dev_1' },
            { 'type' => 'watch', 'id' => 'dev_2' }
          ],
          'metadata' => { 'department' => 'Sales', 'badge_id' => 'B001' },
          'temporary' => true
        }
      end

      subject(:card) { described_class.new(data) }

      it 'sets id' do
        expect(card.id).to eq('card_123')
      end

      it 'sets state' do
        expect(card.state).to eq('active')
      end

      it 'sets url from install_url' do
        expect(card.url).to eq('https://install.example.com/abc')
      end

      it 'sets install_url' do
        expect(card.install_url).to eq('https://install.example.com/abc')
      end

      it 'sets details' do
        expect(card.details).to eq({ 'extra' => 'info' })
      end

      it 'sets full_name' do
        expect(card.full_name).to eq('John Doe')
      end

      it 'sets expiration_date' do
        expect(card.expiration_date).to eq('2025-12-31T00:00:00Z')
      end

      it 'sets card_template_id' do
        expect(card.card_template_id).to eq('tmpl_456')
      end

      it 'sets card_number' do
        expect(card.card_number).to eq('98765')
      end

      it 'sets site_code' do
        expect(card.site_code).to eq('SC100')
      end

      it 'sets file_data' do
        expect(card.file_data).to eq('base64encodeddata')
      end

      it 'sets direct_install_url' do
        expect(card.direct_install_url).to eq('https://direct.example.com/xyz')
      end

      it 'sets devices' do
        expect(card.devices).to eq([
                                     { 'type' => 'iphone', 'id' => 'dev_1' },
                                     { 'type' => 'watch', 'id' => 'dev_2' }
                                   ])
      end

      it 'sets metadata' do
        expect(card.metadata).to eq({ 'department' => 'Sales', 'badge_id' => 'B001' })
      end

      it 'sets temporary' do
        expect(card.temporary).to eq(true)
      end
    end

    context 'with minimal data' do
      let(:data) { { 'id' => 'card_minimal' } }

      subject(:card) { described_class.new(data) }

      it 'sets provided fields' do
        expect(card.id).to eq('card_minimal')
      end

      it 'defaults missing fields to nil' do
        expect(card.state).to be_nil
        expect(card.url).to be_nil
        expect(card.full_name).to be_nil
        expect(card.expiration_date).to be_nil
        expect(card.card_template_id).to be_nil
        expect(card.card_number).to be_nil
        expect(card.site_code).to be_nil
        expect(card.file_data).to be_nil
        expect(card.direct_install_url).to be_nil
        expect(card.details).to be_nil
        expect(card.temporary).to be_nil
      end

      it 'defaults devices to empty array' do
        expect(card.devices).to eq([])
      end

      it 'defaults metadata to empty hash' do
        expect(card.metadata).to eq({})
      end
    end

    context 'with nil data' do
      subject(:card) { described_class.new(nil) }

      it 'handles nil gracefully' do
        expect(card.id).to be_nil
        expect(card.state).to be_nil
        expect(card.devices).to eq([])
        expect(card.metadata).to eq({})
      end
    end

    context 'with empty hash' do
      subject(:card) { described_class.new({}) }

      it 'handles empty hash gracefully' do
        expect(card.id).to be_nil
        expect(card.state).to be_nil
      end
    end
  end

  describe '#to_s' do
    it 'returns a readable string representation' do
      card = described_class.new({
                                   'id' => 'card_abc',
                                   'full_name' => 'Alice Smith',
                                   'state' => 'active'
                                 })

      expect(card.to_s).to eq("Card(name='Alice Smith', id='card_abc', state='active')")
    end

    it 'handles nil values' do
      card = described_class.new({})

      expect(card.to_s).to eq("Card(name='', id='', state='')")
    end
  end

  describe '#inspect' do
    it 'is aliased to #to_s' do
      card = described_class.new({ 'id' => 'card_xyz', 'full_name' => 'Bob', 'state' => 'pending' })

      expect(card.inspect).to eq(card.to_s)
    end
  end
end
