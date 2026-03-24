# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessGrid::PassTemplatePair do
  describe '#initialize' do
    context 'with complete data' do
      let(:data) do
        {
          'id' => 'pair_123',
          'name' => 'Employee Badge Pair',
          'created_at' => '2025-01-01T00:00:00Z',
          'android_template' => {
            'id' => 'tmpl_android_456',
            'name' => 'Employee Badge Android',
            'platform' => 'android'
          },
          'ios_template' => {
            'id' => 'tmpl_ios_789',
            'name' => 'Employee Badge iOS',
            'platform' => 'apple'
          }
        }
      end

      subject(:pair) { described_class.new(data) }

      it 'sets id' do
        expect(pair.id).to eq('pair_123')
      end

      it 'sets name' do
        expect(pair.name).to eq('Employee Badge Pair')
      end

      it 'sets created_at' do
        expect(pair.created_at).to eq('2025-01-01T00:00:00Z')
      end

      it 'sets android_template as TemplateInfo' do
        expect(pair.android_template).to be_a(AccessGrid::TemplateInfo)
        expect(pair.android_template.id).to eq('tmpl_android_456')
        expect(pair.android_template.name).to eq('Employee Badge Android')
        expect(pair.android_template.platform).to eq('android')
      end

      it 'sets ios_template as TemplateInfo' do
        expect(pair.ios_template).to be_a(AccessGrid::TemplateInfo)
        expect(pair.ios_template.id).to eq('tmpl_ios_789')
        expect(pair.ios_template.name).to eq('Employee Badge iOS')
        expect(pair.ios_template.platform).to eq('apple')
      end
    end

    context 'with only ios_template' do
      let(:data) do
        {
          'id' => 'pair_ios_only',
          'name' => 'iOS Only Pair',
          'ios_template' => {
            'id' => 'tmpl_ios',
            'name' => 'iOS Template',
            'platform' => 'apple'
          }
        }
      end

      subject(:pair) { described_class.new(data) }

      it 'sets ios_template' do
        expect(pair.ios_template).to be_a(AccessGrid::TemplateInfo)
      end

      it 'sets android_template to nil' do
        expect(pair.android_template).to be_nil
      end
    end

    context 'with only android_template' do
      let(:data) do
        {
          'id' => 'pair_android_only',
          'name' => 'Android Only Pair',
          'android_template' => {
            'id' => 'tmpl_android',
            'name' => 'Android Template',
            'platform' => 'android'
          }
        }
      end

      subject(:pair) { described_class.new(data) }

      it 'sets android_template' do
        expect(pair.android_template).to be_a(AccessGrid::TemplateInfo)
      end

      it 'sets ios_template to nil' do
        expect(pair.ios_template).to be_nil
      end
    end

    context 'with minimal data' do
      let(:data) { { 'id' => 'pair_minimal' } }

      subject(:pair) { described_class.new(data) }

      it 'sets id' do
        expect(pair.id).to eq('pair_minimal')
      end

      it 'returns nil for missing fields' do
        expect(pair.name).to be_nil
        expect(pair.created_at).to be_nil
        expect(pair.android_template).to be_nil
        expect(pair.ios_template).to be_nil
      end
    end

    context 'with nil data' do
      it 'raises NoMethodError when accessing attributes' do
        expect { described_class.new(nil) }.to raise_error(NoMethodError)
      end
    end

    context 'with empty hash' do
      subject(:pair) { described_class.new({}) }

      it 'returns nil for all fields' do
        expect(pair.id).to be_nil
        expect(pair.name).to be_nil
        expect(pair.android_template).to be_nil
        expect(pair.ios_template).to be_nil
      end
    end
  end
end

RSpec.describe AccessGrid::TemplateInfo do
  describe '#initialize' do
    context 'with complete data' do
      let(:data) do
        {
          'id' => 'tmpl_info_123',
          'name' => 'Template Name',
          'platform' => 'apple'
        }
      end

      subject(:info) { described_class.new(data) }

      it 'sets id' do
        expect(info.id).to eq('tmpl_info_123')
      end

      it 'sets name' do
        expect(info.name).to eq('Template Name')
      end

      it 'sets platform' do
        expect(info.platform).to eq('apple')
      end
    end

    context 'with minimal data' do
      let(:data) { { 'id' => 'tmpl_minimal' } }

      subject(:info) { described_class.new(data) }

      it 'sets id' do
        expect(info.id).to eq('tmpl_minimal')
      end

      it 'returns nil for missing fields' do
        expect(info.name).to be_nil
        expect(info.platform).to be_nil
      end
    end

    context 'with nil data' do
      it 'raises NoMethodError when accessing attributes' do
        expect { described_class.new(nil) }.to raise_error(NoMethodError)
      end
    end

    context 'with empty hash' do
      subject(:info) { described_class.new({}) }

      it 'returns nil for all fields' do
        expect(info.id).to be_nil
        expect(info.name).to be_nil
        expect(info.platform).to be_nil
      end
    end
  end
end
