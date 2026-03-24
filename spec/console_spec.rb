# frozen_string_literal: true

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
        watch_count: 2,
        iphone_count: 3,
        design: {
          background_color: '#FFFFFF',
          label_color: '#000000',
          label_secondary_color: '#666666'
        },
        support_info: {
          support_url: 'https://help.example.com',
          support_email: 'support@example.com',
          support_phone_number: '+1-555-1234',
          privacy_policy_url: 'https://example.com/privacy',
          terms_and_conditions_url: 'https://example.com/terms'
        }
      }
    end

    let(:expected_request_body) do
      {
        name: 'Employee Badge',
        platform: 'apple',
        use_case: 'employee_badge',
        protocol: 'desfire',
        watch_count: 2,
        iphone_count: 3,
        background_color: '#FFFFFF',
        label_color: '#000000',
        label_secondary_color: '#666666',
        support_url: 'https://help.example.com',
        support_email: 'support@example.com',
        support_phone_number: '+1-555-1234',
        privacy_policy_url: 'https://example.com/privacy',
        terms_and_conditions_url: 'https://example.com/terms'
      }
    end

    let(:success_response) do
      {
        id: 'template_123',
        name: 'Employee Badge',
        platform: 'apple',
        protocol: 'desfire',
        allowed_device_counts: {
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
      stub_api_request(:post, '/v1/console/card-templates', body: success_response, request_body: expected_request_body)

      template = console.create_template(template_params)

      expect(template).to be_a(AccessGrid::Template)
      expect(template.id).to eq('template_123')
      expect(template.name).to eq('Employee Badge')
    end

    it 'transforms design and support_info params to flat structure' do
      stub_api_request(:post, '/v1/console/card-templates', body: success_response, request_body: expected_request_body)

      # This test verifies the request body transformation happens correctly
      # If the transformation didn't work, the stub wouldn't match
      expect { console.create_template(template_params) }.not_to raise_error
    end

    it 'handles missing design and support_info' do
      minimal_params = { name: 'Minimal Template', platform: 'apple' }
      minimal_request_body = {
        name: 'Minimal Template',
        platform: 'apple',
        background_color: nil,
        label_color: nil,
        label_secondary_color: nil,
        support_url: nil,
        support_email: nil,
        support_phone_number: nil,
        privacy_policy_url: nil,
        terms_and_conditions_url: nil
      }

      stub_api_request(:post, '/v1/console/card-templates', body: success_response, request_body: minimal_request_body)

      template = console.create_template(minimal_params)
      expect(template).to be_a(AccessGrid::Template)
    end
  end

  describe '#update_template' do
    let(:update_params) do
      {
        name: 'Updated Badge',
        watch_count: 3,
        support_info: {
          support_email: 'new-support@example.com'
        }
      }
    end

    let(:expected_request_body) do
      {
        name: 'Updated Badge',
        watch_count: 3,
        background_color: nil,
        label_color: nil,
        label_secondary_color: nil,
        support_url: nil,
        support_email: 'new-support@example.com',
        support_phone_number: nil,
        privacy_policy_url: nil,
        terms_and_conditions_url: nil
      }
    end

    let(:success_response) do
      {
        id: 'template_123',
        name: 'Updated Badge',
        platform: 'apple',
        allowed_device_counts: { watch: 3, iphone: 3 }
      }
    end

    it 'updates an existing template' do
      stub_api_request(:put, '/v1/console/card-templates/template_123', body: success_response,
                                                                        request_body: expected_request_body)

      template = console.update_template('template_123', update_params)

      expect(template).to be_a(AccessGrid::Template)
      expect(template.id).to eq('template_123')
      expect(template.name).to eq('Updated Badge')
    end
  end

  describe '#read_template' do
    let(:template_response) do
      {
        id: 'template_456',
        name: 'Employee Badge',
        platform: 'apple',
        protocol: 'desfire',
        use_case: 'employee_badge',
        created_at: '2025-01-01T00:00:00Z',
        issued_keys_count: 100,
        active_keys_count: 95
      }
    end

    it 'retrieves a template by id' do
      stub_api_request(
        :get,
        '/v1/console/card-templates/template_456',
        body: template_response,
        query: generate_sig_payload(id: :template_456)
      )

      template = console.read_template('template_456')

      expect(template).to be_a(AccessGrid::Template)
      expect(template.id).to eq('template_456')
      expect(template.name).to eq('Employee Badge')
      expect(template.issued_keys_count).to eq(100)
      expect(template.active_keys_count).to eq(95)
    end
  end

  describe '#get_logs' do
    let(:log_response) do
      {
        logs: [
          {
            event: 'install',
            created_at: '2025-01-01T00:00:00Z',
            ip_address: '127.0.0.1',
            user_agent: 'Test Browser',
            metadata: { user_id: 'user_123' }
          },
          {
            event: 'view',
            created_at: '2025-01-02T00:00:00Z',
            ip_address: '127.0.0.2',
            user_agent: 'Another Browser',
            metadata: { user_id: 'user_456' }
          }
        ],
        pagination: {
          current_page: 1,
          total_pages: 3,
          total_count: 25
        }
      }
    end

    it 'returns full response with logs and pagination' do
      stub_api_request(
        :get,
        '/v1/console/card-templates/template_123/logs',
        body: log_response,
        query: generate_sig_payload(id: :logs)
      )

      response = console.get_logs('template_123')

      expect(response).to be_a(Hash)
      expect(response['logs']).to be_an(Array)
      expect(response['logs'].length).to eq(2)
      expect(response['logs'].first).to be_an(AccessGrid::Event)
      expect(response['logs'].first.type).to eq('install')
      expect(response['pagination']).to eq({
                                             'current_page' => 1,
                                             'total_pages' => 3,
                                             'total_count' => 25
                                           })
    end

    it 'accepts filter params' do
      filter_params = { device: 'mobile', event_type: 'install' }
      query = filter_params.merge(generate_sig_payload(id: :logs))

      stub_api_request(
        :get,
        '/v1/console/card-templates/template_123/logs',
        body: log_response,
        query: query
      )

      response = console.get_logs('template_123', filter_params)

      expect(response['logs']).to be_an(Array)
    end

    it 'handles empty logs' do
      empty_response = { logs: [], pagination: { current_page: 1, total_pages: 0 } }

      stub_api_request(
        :get,
        '/v1/console/card-templates/template_empty/logs',
        body: empty_response,
        query: generate_sig_payload(id: :logs)
      )

      response = console.get_logs('template_empty')

      expect(response['logs']).to eq([])
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
      injected_params = generate_sig_payload(id: :logs)

      params = {
        filters: {
          device: 'mobile',
          start_date: '2025-01-01T00:00:00Z'
        }
      }

      query = params.merge(injected_params)

      stub_api_request(:get, '/v1/console/card-templates/template_123/logs', body: log_response, query: query)

      events = console.event_log(params.merge(card_template_id: 'template_123'))

      expect(events).to be_an(Array)
      expect(events.first).to be_an(AccessGrid::Event)
      expect(events.first.type).to eq('install')
    end

    it 'returns empty array when no logs' do
      empty_response = { logs: nil, pagination: {} }

      stub_api_request(
        :get,
        '/v1/console/card-templates/template_empty/logs',
        body: empty_response,
        query: generate_sig_payload(id: :logs)
      )

      events = console.event_log(card_template_id: 'template_empty')

      expect(events).to eq([])
    end
  end

  describe '#list_pass_template_pairs' do
    let(:pairs_response) do
      {
        pass_template_pairs: [
          {
            id: 'pair_1',
            name: 'Employee Badge Pair',
            created_at: '2025-01-01T00:00:00Z',
            ios_template: { id: 'tmpl_ios_1', name: 'iOS Badge', platform: 'apple' },
            android_template: { id: 'tmpl_android_1', name: 'Android Badge', platform: 'android' }
          },
          {
            id: 'pair_2',
            name: 'Contractor Badge Pair',
            created_at: '2025-01-02T00:00:00Z',
            ios_template: { id: 'tmpl_ios_2', name: 'iOS Contractor', platform: 'apple' },
            android_template: nil
          }
        ],
        pagination: {
          current_page: 1,
          total_pages: 1
        }
      }
    end

    it 'returns pass template pairs' do
      stub_api_request(
        :get,
        '/v1/console/pass-template-pairs',
        body: pairs_response,
        query: generate_sig_payload(id: :'pass-template-pairs')
      )

      response = console.list_pass_template_pairs

      expect(response).to be_a(Hash)
      expect(response['pass_template_pairs']).to be_an(Array)
      expect(response['pass_template_pairs'].length).to eq(2)

      first_pair = response['pass_template_pairs'].first
      expect(first_pair).to be_a(AccessGrid::PassTemplatePair)
      expect(first_pair.id).to eq('pair_1')
      expect(first_pair.ios_template).to be_a(AccessGrid::TemplateInfo)
      expect(first_pair.android_template).to be_a(AccessGrid::TemplateInfo)
    end

    it 'accepts pagination params' do
      query = { page: 2, per_page: 10 }.merge(generate_sig_payload(id: :'pass-template-pairs'))

      stub_api_request(
        :get,
        '/v1/console/pass-template-pairs',
        body: pairs_response,
        query: query
      )

      response = console.list_pass_template_pairs(page: 2, per_page: 10)

      expect(response['pass_template_pairs']).to be_an(Array)
    end

    it 'handles empty response' do
      empty_response = { pass_template_pairs: [], pagination: { current_page: 1, total_pages: 0 } }

      stub_api_request(
        :get,
        '/v1/console/pass-template-pairs',
        body: empty_response,
        query: generate_sig_payload(id: :'pass-template-pairs')
      )

      response = console.list_pass_template_pairs

      expect(response['pass_template_pairs']).to eq([])
    end

    it 'handles nil pass_template_pairs in response' do
      nil_response = { pass_template_pairs: nil }

      stub_api_request(
        :get,
        '/v1/console/pass-template-pairs',
        body: nil_response,
        query: generate_sig_payload(id: :'pass-template-pairs')
      )

      response = console.list_pass_template_pairs

      expect(response['pass_template_pairs']).to be_nil
    end
  end

  describe '#list_ledger_items' do
    let(:ledger_response) do
      {
        ledger_items: [
          {
            created_at: '2025-06-15T14:30:00Z',
            amount: -1.50,
            ex_id: 'li_abc123',
            kind: 'access_pass_debit',
            metadata: {
              access_pass_ex_id: 'ap_xyz',
              pass_template_ex_id: 'pt_456'
            },
            access_pass: {
              ex_id: 'ap_xyz',
              full_name: 'Jane Doe',
              state: 'active',
              metadata: { department: 'Engineering' },
              unified_access_pass_ex_id: 'uap_789',
              pass_template: {
                ex_id: 'pt_456',
                name: 'Employee Badge',
                protocol: 'desfire',
                platform: 'apple',
                use_case: 'employee_badge'
              }
            }
          },
          {
            created_at: '2025-06-14T08:15:00Z',
            amount: 500.00,
            ex_id: 'li_def456',
            kind: 'credit',
            metadata: {},
            access_pass: nil
          }
        ],
        pagination: {
          current_page: 1,
          per_page: 50,
          total_pages: 3,
          total_count: 125
        }
      }
    end

    it 'returns ledger items with nested objects' do
      stub_api_request(
        :get,
        '/v1/console/ledger-items',
        body: ledger_response,
        query: generate_sig_payload(id: :'ledger-items')
      )

      response = console.list_ledger_items

      expect(response).to be_a(Hash)
      expect(response['ledger_items']).to be_an(Array)
      expect(response['ledger_items'].length).to eq(2)

      item = response['ledger_items'].first
      expect(item).to be_a(AccessGrid::LedgerItem)
      expect(item.created_at).to eq('2025-06-15T14:30:00Z')
      expect(item.amount).to eq(-1.50)
      expect(item.id).to eq('li_abc123')
      expect(item.kind).to eq('access_pass_debit')
      expect(item.metadata).to eq({
                                    'access_pass_ex_id' => 'ap_xyz',
                                    'pass_template_ex_id' => 'pt_456'
                                  })

      ap = item.access_pass
      expect(ap).to be_a(AccessGrid::LedgerItemAccessPass)
      expect(ap.id).to eq('ap_xyz')
      expect(ap.full_name).to eq('Jane Doe')
      expect(ap.state).to eq('active')
      expect(ap.metadata).to eq({ 'department' => 'Engineering' })
      expect(ap.unified_access_pass_ex_id).to eq('uap_789')

      pt = ap.pass_template
      expect(pt).to be_a(AccessGrid::LedgerItemPassTemplate)
      expect(pt.id).to eq('pt_456')
      expect(pt.name).to eq('Employee Badge')
      expect(pt.protocol).to eq('desfire')
      expect(pt.platform).to eq('apple')
      expect(pt.use_case).to eq('employee_badge')

      expect(response['pagination']).to eq({
                                             'current_page' => 1,
                                             'per_page' => 50,
                                             'total_pages' => 3,
                                             'total_count' => 125
                                           })
    end

    it 'accepts pagination and date filter params' do
      query = {
        page: 2,
        per_page: 20,
        start_date: '2025-01-01T00:00:00Z',
        end_date: '2025-06-30T23:59:59Z'
      }.merge(generate_sig_payload(id: :'ledger-items'))

      stub_api_request(
        :get,
        '/v1/console/ledger-items',
        body: ledger_response,
        query: query
      )

      response = console.list_ledger_items(
        page: 2,
        per_page: 20,
        start_date: '2025-01-01T00:00:00Z',
        end_date: '2025-06-30T23:59:59Z'
      )

      expect(response['ledger_items']).to be_an(Array)
    end

    it 'handles null access_pass on a ledger item' do
      null_ap_response = {
        ledger_items: [
          {
            created_at: '2025-06-14T08:15:00Z',
            amount: 500.00,
            ex_id: 'li_credit',
            kind: 'credit',
            metadata: {},
            access_pass: nil
          }
        ],
        pagination: { current_page: 1, per_page: 50, total_pages: 1, total_count: 1 }
      }

      stub_api_request(
        :get,
        '/v1/console/ledger-items',
        body: null_ap_response,
        query: generate_sig_payload(id: :'ledger-items')
      )

      response = console.list_ledger_items

      item = response['ledger_items'].first
      expect(item.kind).to eq('credit')
      expect(item.access_pass).to be_nil
    end

    it 'handles missing pass_template on an access_pass' do
      missing_pt_response = {
        ledger_items: [
          {
            created_at: '2025-06-15T14:30:00Z',
            amount: -1.50,
            ex_id: 'li_no_pt',
            kind: 'access_pass_debit',
            metadata: {},
            access_pass: {
              ex_id: 'ap_orphan',
              full_name: 'John Smith',
              state: 'suspended',
              metadata: {},
              unified_access_pass_ex_id: nil
            }
          }
        ],
        pagination: { current_page: 1, per_page: 50, total_pages: 1, total_count: 1 }
      }

      stub_api_request(
        :get,
        '/v1/console/ledger-items',
        body: missing_pt_response,
        query: generate_sig_payload(id: :'ledger-items')
      )

      response = console.list_ledger_items

      ap = response['ledger_items'].first.access_pass
      expect(ap).to be_a(AccessGrid::LedgerItemAccessPass)
      expect(ap.full_name).to eq('John Smith')
      expect(ap.unified_access_pass_ex_id).to be_nil
      expect(ap.pass_template).to be_nil
    end

    it 'handles empty response' do
      empty_response = {
        ledger_items: [],
        pagination: { current_page: 1, per_page: 50, total_pages: 0, total_count: 0 }
      }

      stub_api_request(
        :get,
        '/v1/console/ledger-items',
        body: empty_response,
        query: generate_sig_payload(id: :'ledger-items')
      )

      response = console.list_ledger_items

      expect(response['ledger_items']).to eq([])
    end
  end
end
