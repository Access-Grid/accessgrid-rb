# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessGrid::Event do
  describe '#initialize' do
    context 'with complete data' do
      let(:data) do
        {
          'event' => 'install',
          'created_at' => '2025-01-15T10:30:00Z',
          'ip_address' => '192.168.1.100',
          'user_agent' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0)',
          'metadata' => {
            'user_id' => 'user_456',
            'device' => 'mobile',
            'card_id' => 'card_789'
          }
        }
      end

      subject(:event) { described_class.new(data) }

      it 'sets type from event field' do
        expect(event.type).to eq('install')
      end

      it 'sets timestamp from created_at field' do
        expect(event.timestamp).to eq('2025-01-15T10:30:00Z')
      end

      it 'sets user_id from metadata' do
        expect(event.user_id).to eq('user_456')
      end

      it 'sets ip_address' do
        expect(event.ip_address).to eq('192.168.1.100')
      end

      it 'sets user_agent' do
        expect(event.user_agent).to eq('Mozilla/5.0 (iPhone; CPU iPhone OS 17_0)')
      end

      it 'sets metadata' do
        expect(event.metadata).to eq({
                                       'user_id' => 'user_456',
                                       'device' => 'mobile',
                                       'card_id' => 'card_789'
                                     })
      end
    end

    context 'with metadata missing user_id' do
      let(:data) do
        {
          'event' => 'view',
          'created_at' => '2025-01-15T10:30:00Z',
          'metadata' => { 'device' => 'watch' }
        }
      end

      subject(:event) { described_class.new(data) }

      it 'sets user_id to nil' do
        expect(event.user_id).to be_nil
      end

      it 'still sets metadata' do
        expect(event.metadata).to eq({ 'device' => 'watch' })
      end
    end

    context 'with nil metadata' do
      let(:data) do
        {
          'event' => 'uninstall',
          'created_at' => '2025-01-15T10:30:00Z',
          'metadata' => nil
        }
      end

      subject(:event) { described_class.new(data) }

      it 'sets user_id to nil' do
        expect(event.user_id).to be_nil
      end

      it 'sets metadata to nil' do
        expect(event.metadata).to be_nil
      end
    end

    context 'with missing metadata key' do
      let(:data) do
        {
          'event' => 'suspend',
          'created_at' => '2025-01-15T10:30:00Z'
        }
      end

      subject(:event) { described_class.new(data) }

      it 'sets user_id to nil' do
        expect(event.user_id).to be_nil
      end

      it 'sets metadata to nil' do
        expect(event.metadata).to be_nil
      end
    end

    context 'with minimal data' do
      let(:data) { { 'event' => 'unknown' } }

      subject(:event) { described_class.new(data) }

      it 'sets type' do
        expect(event.type).to eq('unknown')
      end

      it 'returns nil for missing fields' do
        expect(event.timestamp).to be_nil
        expect(event.ip_address).to be_nil
        expect(event.user_agent).to be_nil
        expect(event.user_id).to be_nil
        expect(event.metadata).to be_nil
      end
    end

    context 'with nil data' do
      it 'raises NoMethodError when accessing attributes' do
        expect { described_class.new(nil) }.to raise_error(NoMethodError)
      end
    end

    context 'with empty hash' do
      subject(:event) { described_class.new({}) }

      it 'returns nil for all fields' do
        expect(event.type).to be_nil
        expect(event.timestamp).to be_nil
        expect(event.user_id).to be_nil
      end
    end
  end
end
