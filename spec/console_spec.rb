require 'spec_helper'

RSpec.describe AccessGrid::Console do
  let(:client) { AccessGrid.new('test_account', 'test_secret') }
  let(:console) { client.console }

  describe '#create_template' do
    let(:template_params) do
      {
        name: 'Employee Badge',
        platform: 'apple',
        use_case: 'employee_badge',
        protocol: 'desfire',
        allow_on_multiple_devices: true,
        watch_count: 2,
        iphone_count: 3,
        design: {
          background_color: '#FFFFFF',
          label_color: '#000000'
        },
        support_info: {
          support_url: 'https://help.example.com',
          support_email: 'support@example.com'
        }
      }
    end

    let(:success_response) do
      {
        id: 'template_123',
        name: 'Employee Badge',
        platform: 'apple',
        protocol: 'desfire',
        allowed_device_counts: {
          allow_on_multiple_devices: true,
          watch: 2,
          iphone: 3
        },
        support_settings: {
          support_url: 'https://help.example.com',
          support_email: 'support@example.com'
        },
        style_settings: {
          background_color: '#FFFFFF',
          label_color: '#000000'
        }
      }
    end

    it 'creates a new template' do
      stub_api_request(:post, '/api/v1/enterprise/templates', body: success_response)
      
      template = console.create_template(template_params)
      
      expect(template).to be_a(AccessGrid::Template)
      expect(template.id).to eq('template_123')
      expect(template.name).to eq('Employee Badge')
      expect(template.allow_on_multiple_devices).to be true
    end
  end

  describe '#event_log' do
    let(:log_response) do
      {
        logs: [
          {
            event: 'install',
            created_at: '2025-01-01T00:00:00Z',
            ip_address: '127.0.0.1',
            user_agent: 'Test Browser',
            metadata: {
              user_id: 'user_123',
              device: 'mobile'
            }
          }
        ],
        pagination: {
          current_page: 1,
          total_pages: 1
        }
      }
    end

    it 'fetches event logs with filters' do
      stub_api_request(
        :get,
        '/api/v1/enterprise/templates/template_123/logs',
        body: log_response
      )
      
      events = console.event_log(
        card_template_id: 'template_123',
        filters: {
          device: 'mobile',
          start_date: '2025-01-01T00:00:00Z'
        }
      )
      
      expect(events).to be_an(Array)
      expect(events.first).to be_an(AccessGrid::Event)
      expect(events.first.type).to eq('install')
    end
  end
end