# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessGrid::Template do
  describe '#initialize' do
    context 'with complete data' do
      let(:data) do
        {
          'id' => 'tmpl_123',
          'name' => 'Employee Badge',
          'platform' => 'apple',
          'protocol' => 'desfire',
          'use_case' => 'employee_badge',
          'created_at' => '2025-01-01T00:00:00Z',
          'last_published_at' => '2025-01-15T00:00:00Z',
          'issued_keys_count' => 150,
          'active_keys_count' => 142,
          'allowed_device_counts' => { 'iphone' => 3, 'watch' => 2 },
          'support_settings' => {
            'support_url' => 'https://help.example.com',
            'support_email' => 'support@example.com'
          },
          'terms_settings' => {
            'privacy_policy_url' => 'https://example.com/privacy',
            'terms_url' => 'https://example.com/terms'
          },
          'style_settings' => {
            'background_color' => '#FFFFFF',
            'label_color' => '#000000'
          }
        }
      end

      subject(:template) { described_class.new(data) }

      it 'sets id' do
        expect(template.id).to eq('tmpl_123')
      end

      it 'sets name' do
        expect(template.name).to eq('Employee Badge')
      end

      it 'sets platform' do
        expect(template.platform).to eq('apple')
      end

      it 'sets protocol' do
        expect(template.protocol).to eq('desfire')
      end

      it 'sets use_case' do
        expect(template.use_case).to eq('employee_badge')
      end

      it 'sets created_at' do
        expect(template.created_at).to eq('2025-01-01T00:00:00Z')
      end

      it 'sets last_published_at' do
        expect(template.last_published_at).to eq('2025-01-15T00:00:00Z')
      end

      it 'sets issued_keys_count' do
        expect(template.issued_keys_count).to eq(150)
      end

      it 'sets active_keys_count' do
        expect(template.active_keys_count).to eq(142)
      end

      it 'sets allowed_device_counts' do
        expect(template.allowed_device_counts).to eq({ 'iphone' => 3, 'watch' => 2 })
      end

      it 'sets support_settings' do
        expect(template.support_settings).to eq({
                                                  'support_url' => 'https://help.example.com',
                                                  'support_email' => 'support@example.com'
                                                })
      end

      it 'sets terms_settings' do
        expect(template.terms_settings).to eq({
                                                'privacy_policy_url' => 'https://example.com/privacy',
                                                'terms_url' => 'https://example.com/terms'
                                              })
      end

      it 'sets style_settings' do
        expect(template.style_settings).to eq({
                                                'background_color' => '#FFFFFF',
                                                'label_color' => '#000000'
                                              })
      end
    end

    context 'with minimal data' do
      let(:data) { { 'id' => 'tmpl_minimal', 'name' => 'Basic Template' } }

      subject(:template) { described_class.new(data) }

      it 'sets provided fields' do
        expect(template.id).to eq('tmpl_minimal')
        expect(template.name).to eq('Basic Template')
      end

      it 'returns nil for missing fields' do
        expect(template.platform).to be_nil
        expect(template.protocol).to be_nil
        expect(template.use_case).to be_nil
        expect(template.created_at).to be_nil
        expect(template.last_published_at).to be_nil
        expect(template.issued_keys_count).to be_nil
        expect(template.active_keys_count).to be_nil
        expect(template.allowed_device_counts).to be_nil
        expect(template.support_settings).to be_nil
        expect(template.terms_settings).to be_nil
        expect(template.style_settings).to be_nil
      end
    end

    context 'with nil data' do
      it 'raises NoMethodError when accessing attributes' do
        expect { described_class.new(nil) }.to raise_error(NoMethodError)
      end
    end

    context 'with empty hash' do
      subject(:template) { described_class.new({}) }

      it 'returns nil for all fields' do
        expect(template.id).to be_nil
        expect(template.name).to be_nil
        expect(template.platform).to be_nil
      end
    end
  end
end
