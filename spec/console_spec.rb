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
        use_case: 'corporate_id',
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
        use_case: 'corporate_id',
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

    it 'handles flat params without nested design/support_info' do
      flat_params = {
        name: 'Flat Template',
        platform: 'apple',
        background_color: '#FFFFFF',
        support_url: 'https://help.example.com'
      }

      stub_api_request(:post, '/v1/console/card-templates', body: success_response, request_body: flat_params)

      template = console.create_template(flat_params)
      expect(template).to be_a(AccessGrid::Template)
    end

    it 'handles minimal params' do
      minimal_params = { name: 'Minimal Template', platform: 'apple' }

      stub_api_request(:post, '/v1/console/card-templates', body: success_response, request_body: minimal_params)

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
        support_email: 'new-support@example.com'
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
        use_case: 'corporate_id',
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
        card_template_pairs: [
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
        '/v1/console/card-template-pairs',
        body: pairs_response,
        query: generate_sig_payload(id: :'card-template-pairs')
      )

      response = console.list_pass_template_pairs

      expect(response).to be_a(Hash)
      expect(response['card_template_pairs']).to be_an(Array)
      expect(response['card_template_pairs'].length).to eq(2)

      first_pair = response['card_template_pairs'].first
      expect(first_pair).to be_a(AccessGrid::PassTemplatePair)
      expect(first_pair.id).to eq('pair_1')
      expect(first_pair.ios_template).to be_a(AccessGrid::TemplateInfo)
      expect(first_pair.android_template).to be_a(AccessGrid::TemplateInfo)
    end

    it 'accepts pagination params' do
      query = { page: 2, per_page: 10 }.merge(generate_sig_payload(id: :'card-template-pairs'))

      stub_api_request(
        :get,
        '/v1/console/card-template-pairs',
        body: pairs_response,
        query: query
      )

      response = console.list_pass_template_pairs(page: 2, per_page: 10)

      expect(response['card_template_pairs']).to be_an(Array)
    end

    it 'handles empty response' do
      empty_response = { card_template_pairs: [], pagination: { current_page: 1, total_pages: 0 } }

      stub_api_request(
        :get,
        '/v1/console/card-template-pairs',
        body: empty_response,
        query: generate_sig_payload(id: :'card-template-pairs')
      )

      response = console.list_pass_template_pairs

      expect(response['card_template_pairs']).to eq([])
    end

    it 'handles nil card_template_pairs in response' do
      nil_response = { card_template_pairs: nil }

      stub_api_request(
        :get,
        '/v1/console/card-template-pairs',
        body: nil_response,
        query: generate_sig_payload(id: :'card-template-pairs')
      )

      response = console.list_pass_template_pairs

      expect(response['card_template_pairs']).to be_nil
    end
  end

  describe '#list_ledger_items' do
    let(:ledger_response) do
      {
        ledger_items: [
          {
            created_at: '2025-06-15T14:30:00Z',
            amount: -1.50,
            id: 'li_abc123',
            kind: 'access_pass_debit',
            metadata: {
              access_pass_ex_id: 'ap_xyz',
              pass_template_ex_id: 'pt_456'
            },
            access_pass: {
              id: 'ap_xyz',
              full_name: 'Jane Doe',
              state: 'active',
              metadata: { department: 'Engineering' },
              unified_access_pass_ex_id: 'uap_789',
              pass_template: {
                id: 'pt_456',
                name: 'Employee Badge',
                protocol: 'desfire',
                platform: 'apple',
                use_case: 'corporate_id'
              }
            }
          },
          {
            created_at: '2025-06-14T08:15:00Z',
            amount: 500.00,
            id: 'li_def456',
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
      expect(pt.use_case).to eq('corporate_id')

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
            id: 'li_credit',
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
            id: 'li_no_pt',
            kind: 'access_pass_debit',
            metadata: {},
            access_pass: {
              id: 'ap_orphan',
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

  describe '#ledger_items' do
    it 'is an alias for list_ledger_items' do
      expect(console.method(:ledger_items)).to eq(console.method(:list_ledger_items))
    end
  end

  describe '#publish_template' do
    it 'POSTs to the publish endpoint and returns id + status' do
      stub_api_request(
        :post,
        '/v1/console/card-templates/tmpl_123/publish',
        body: { id: 'tmpl_123', status: 'in-review' },
        query: generate_sig_payload(id: 'tmpl_123')
      )

      result = console.publish_template('tmpl_123')

      expect(result).to be_a(AccessGrid::PublishTemplateResponse)
      expect(result.id).to eq('tmpl_123')
      expect(result.status).to eq('in-review')
    end

    it 'returns status "ready" for Android templates' do
      stub_api_request(
        :post,
        '/v1/console/card-templates/tmpl_456/publish',
        body: { id: 'tmpl_456', status: 'ready' },
        query: generate_sig_payload(id: 'tmpl_456')
      )

      expect(console.publish_template('tmpl_456').status).to eq('ready')
    end
  end

  describe '#reveal_smart_tap' do
    # Captured wire-compat fixture — same caller keypair + envelope used in
    # Elixir / PHP / Java specs. The caller_private_key is ephemeral and
    # single-use by design (server rejects reuse on pubkey fingerprint), so
    # committing it carries no credential risk.
    let(:fixture_caller_private_key_pem) do
      <<~PEM
        -----BEGIN EC PRIVATE KEY-----
        MHcCAQEEIIou+Kk08kWAjhi0WyIx+L2GrgStGBCPODlwKYKd5BydoAoGCCqGSM49
        AwEHoUQDQgAE+gnDxXJt1SBaCK8roKH8QvOa/ItdQUe85JIsUc6RvhD/udLaFtHY
        m+MnOmeSdVaKTPWudH0+iGbleB3kS7lYxQ==
        -----END EC PRIVATE KEY-----
      PEM
    end

    let(:fixture_envelope) do
      {
        'alg' => 'ECDH-ES+A256GCM',
        'ciphertext' => 'ckYyA3FdRYjOFI/FKz/QeR5Yf9nZZFzo73kDXKZSB/EgbQ==',
        'ephemeral_public_key' =>
          "-----BEGIN PUBLIC KEY-----\n" \
          "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE7mg6i99GcIVutMPr/PXSBSQVlbLM\n" \
          "tnJO10ZBjk9ZTfw6wwAVNBnDBiqY7VrdOG1JdFOYoac+NkAlyMRGYk2tVQ==\n" \
          "-----END PUBLIC KEY-----\n",
        'iv' => '5X2OCht+kLB/xQmX',
        'tag' => '0vwkjVaCwi5zl37xvJPxeg=='
      }
    end

    let(:fixture_priv) { OpenSSL::PKey::EC.new(fixture_caller_private_key_pem) }
    let(:fixture_pub_pem) { fixture_priv.public_to_pem }

    it 'returns the decrypted SmartTap PEM' do
      allow(AccessGrid::SmartTapRevealCrypto).to receive(:generate_keypair).and_return(
        priv: fixture_priv, pub_pem: fixture_pub_pem
      )

      stub_api_request(
        :post,
        '/v1/console/card-templates/tmpl-42/smart-tap/reveal',
        body: {
          key_version: 'tmpl-42',
          collector_id: '12345678',
          fingerprint: 'sha256:deadbeef',
          encrypted_private_key: fixture_envelope
        }
      )

      result = console.reveal_smart_tap('tmpl-42')

      expect(result).to be_a(AccessGrid::RevealTemplatePrivateKey)
      expect(result.key_version).to eq('tmpl-42')
      expect(result.collector_id).to eq('12345678')
      expect(result.fingerprint).to eq('sha256:deadbeef')
      expect(result.private_key).to eq('FIXTURE-PLAINTEXT-NOT-A-CREDENTIAL')
    end
  end

  describe '#ios_preflight' do
    let(:preflight_response) do
      {
        provisioningCredentialIdentifier: 'prov_cred_123',
        sharingInstanceIdentifier: 'share_inst_456',
        cardTemplateIdentifier: 'card_tmpl_789',
        environmentIdentifier: 'env_abc'
      }
    end

    it 'returns an IosPreflight object' do
      stub_api_request(
        :post,
        '/v1/console/card-templates/tmpl_123/ios_preflight',
        body: preflight_response,
        request_body: { access_pass_ex_id: 'pass_456' }
      )

      result = console.ios_preflight(
        card_template_id: 'tmpl_123',
        access_pass_ex_id: 'pass_456'
      )

      expect(result).to be_a(AccessGrid::IosPreflight)
      expect(result.provisioning_credential_identifier).to eq('prov_cred_123')
      expect(result.sharing_instance_identifier).to eq('share_inst_456')
      expect(result.card_template_identifier).to eq('card_tmpl_789')
      expect(result.environment_identifier).to eq('env_abc')
    end
  end

  describe '#webhooks' do
    let(:webhooks_service) { console.webhooks }

    describe '#create' do
      let(:create_response) do
        {
          id: 'wh_123',
          name: 'Production',
          url: 'https://example.com/webhooks',
          auth_method: 'bearer_token',
          subscribed_events: ['ag.access_pass.issued'],
          created_at: '2025-01-01T00:00:00Z',
          private_key: 'pk_secret_123'
        }
      end

      it 'creates a webhook' do
        stub_api_request(
          :post,
          '/v1/console/webhooks',
          body: create_response,
          request_body: {
            name: 'Production',
            url: 'https://example.com/webhooks',
            subscribed_events: ['ag.access_pass.issued'],
            auth_method: 'bearer_token'
          }
        )

        webhook = webhooks_service.create(
          name: 'Production',
          url: 'https://example.com/webhooks',
          subscribed_events: ['ag.access_pass.issued']
        )

        expect(webhook).to be_a(AccessGrid::Webhook)
        expect(webhook.id).to eq('wh_123')
        expect(webhook.name).to eq('Production')
        expect(webhook.private_key).to eq('pk_secret_123')
      end
    end

    describe '#list' do
      let(:list_response) do
        {
          webhooks: [
            { id: 'wh_1', name: 'Prod', url: 'https://example.com/wh1', auth_method: 'bearer_token' },
            { id: 'wh_2', name: 'Staging', url: 'https://example.com/wh2', auth_method: 'bearer_token' }
          ],
          pagination: { current_page: 1, total_pages: 1 }
        }
      end

      it 'lists webhooks' do
        stub_api_request(
          :get,
          '/v1/console/webhooks',
          body: list_response,
          query: generate_sig_payload(id: :webhooks)
        )

        webhooks = webhooks_service.list

        expect(webhooks).to be_an(Array)
        expect(webhooks.length).to eq(2)
        expect(webhooks.first).to be_a(AccessGrid::Webhook)
        expect(webhooks.first.id).to eq('wh_1')
      end
    end

    describe '#delete' do
      it 'deletes a webhook' do
        stub_api_request(
          :delete,
          '/v1/console/webhooks/wh_123',
          status: 204,
          body: {},
          query: generate_sig_payload(id: :wh_123)
        )

        result = webhooks_service.delete('wh_123')
        expect(result).to eq({})
      end
    end
  end

  describe '#list_landing_pages' do
    let(:landing_pages_response) do
      [
        {
          id: 'lp_1',
          name: 'Miami Office',
          created_at: '2025-01-01T00:00:00Z',
          kind: 'universal',
          password_protected: false,
          logo_url: 'https://example.com/logo.png'
        },
        {
          id: 'lp_2',
          name: 'NYC Office',
          created_at: '2025-01-02T00:00:00Z',
          kind: 'universal',
          password_protected: true,
          logo_url: nil
        }
      ]
    end

    it 'returns a list of landing pages' do
      stub_api_request(
        :get,
        '/v1/console/landing-pages',
        body: landing_pages_response,
        query: generate_sig_payload(id: :'landing-pages')
      )

      pages = console.list_landing_pages

      expect(pages).to be_an(Array)
      expect(pages.length).to eq(2)
      expect(pages.first).to be_a(AccessGrid::LandingPage)
      expect(pages.first.id).to eq('lp_1')
      expect(pages.first.name).to eq('Miami Office')
      expect(pages.first.kind).to eq('universal')
      expect(pages.first.password_protected).to eq(false)
      expect(pages.first.logo_url).to eq('https://example.com/logo.png')
    end

    it 'returns empty array when no landing pages' do
      stub_api_request(
        :get,
        '/v1/console/landing-pages',
        body: [],
        query: generate_sig_payload(id: :'landing-pages')
      )

      pages = console.list_landing_pages
      expect(pages).to eq([])
    end
  end

  describe '#create_landing_page' do
    let(:create_response) do
      {
        id: 'lp_new',
        name: 'Miami Office Access Pass',
        created_at: '2025-06-01T00:00:00Z',
        kind: 'universal',
        password_protected: false,
        logo_url: nil
      }
    end

    it 'creates a landing page' do
      request_body = {
        name: 'Miami Office Access Pass',
        kind: 'universal',
        additional_text: 'Welcome to the Miami Office',
        bg_color: '#f1f5f9',
        allow_immediate_download: true
      }

      stub_api_request(
        :post,
        '/v1/console/landing-pages',
        body: create_response,
        request_body: request_body
      )

      page = console.create_landing_page(**request_body)

      expect(page).to be_a(AccessGrid::LandingPage)
      expect(page.id).to eq('lp_new')
      expect(page.name).to eq('Miami Office Access Pass')
      expect(page.kind).to eq('universal')
    end
  end

  describe '#update_landing_page' do
    let(:update_response) do
      {
        id: 'lp_1',
        name: 'Updated Miami Office',
        created_at: '2025-06-01T00:00:00Z',
        kind: 'universal',
        password_protected: false,
        logo_url: nil
      }
    end

    it 'updates a landing page' do
      request_body = {
        name: 'Updated Miami Office',
        additional_text: 'Welcome!',
        bg_color: '#e2e8f0'
      }

      stub_api_request(
        :put,
        '/v1/console/landing-pages/lp_1',
        body: update_response,
        request_body: request_body
      )

      page = console.update_landing_page(landing_page_id: 'lp_1', **request_body)

      expect(page).to be_a(AccessGrid::LandingPage)
      expect(page.id).to eq('lp_1')
      expect(page.name).to eq('Updated Miami Office')
    end
  end

  describe 'credential_profiles' do
    let(:profiles_service) { console.credential_profiles }

    describe '#create' do
      let(:create_response) do
        {
          id: 'cp_123',
          aid: 'F0394148',
          name: 'Main Office Profile',
          apple_id: 'pass.com.example',
          created_at: '2025-06-01T00:00:00Z',
          card_storage: 2048,
          keys: [{ 'value' => 'abcdef1234567890abcdef1234567890' }],
          files: []
        }
      end

      it 'creates a credential profile' do
        request_body = {
          name: 'Main Office Profile',
          app_name: 'KEY-ID-main',
          keys: [{ value: 'abcdef1234567890abcdef1234567890' }]
        }

        stub_api_request(
          :post,
          '/v1/console/credential-profiles',
          body: create_response,
          request_body: request_body
        )

        profile = profiles_service.create(**request_body)

        expect(profile).to be_a(AccessGrid::CredentialProfile)
        expect(profile.id).to eq('cp_123')
        expect(profile.aid).to eq('F0394148')
        expect(profile.name).to eq('Main Office Profile')
        expect(profile.keys).to eq([{ 'value' => 'abcdef1234567890abcdef1234567890' }])
      end
    end

    describe '#list' do
      let(:list_response) do
        [
          {
            id: 'cp_1',
            aid: 'F0394148',
            name: 'Profile A',
            apple_id: nil,
            created_at: '2025-01-01T00:00:00Z',
            card_storage: 2048,
            keys: [],
            files: []
          },
          {
            id: 'cp_2',
            aid: 'F0394149',
            name: 'Profile B',
            apple_id: nil,
            created_at: '2025-01-02T00:00:00Z',
            card_storage: 4096,
            keys: [],
            files: []
          }
        ]
      end

      it 'returns a list of credential profiles' do
        stub_api_request(
          :get,
          '/v1/console/credential-profiles',
          body: list_response,
          query: generate_sig_payload(id: :'credential-profiles')
        )

        profiles = profiles_service.list

        expect(profiles).to be_an(Array)
        expect(profiles.length).to eq(2)
        expect(profiles.first).to be_a(AccessGrid::CredentialProfile)
        expect(profiles.first.id).to eq('cp_1')
        expect(profiles.first.aid).to eq('F0394148')
        expect(profiles.last.id).to eq('cp_2')
      end

      it 'returns empty array when no profiles' do
        stub_api_request(
          :get,
          '/v1/console/credential-profiles',
          body: [],
          query: generate_sig_payload(id: :'credential-profiles')
        )

        profiles = profiles_service.list
        expect(profiles).to eq([])
      end
    end
  end

  describe 'HID orgs' do
    let(:org_response) do
      {
        id: 'org_123',
        name: 'My Org',
        slug: 'my-org',
        first_name: 'Ada',
        last_name: 'Lovelace',
        phone: '+1-555-0000',
        full_address: '1 Main St, NY NY',
        status: 'pending',
        created_at: '2025-01-01T00:00:00Z'
      }
    end

    describe '#hid.orgs.create' do
      it 'creates a new HID org' do
        request_body = {
          name: 'My Org',
          full_address: '1 Main St, NY NY',
          phone: '+1-555-0000',
          first_name: 'Ada',
          last_name: 'Lovelace'
        }

        stub_api_request(:post, '/v1/console/hid/orgs', body: org_response, request_body: request_body)

        org = console.hid.orgs.create(
          name: 'My Org',
          full_address: '1 Main St, NY NY',
          phone: '+1-555-0000',
          first_name: 'Ada',
          last_name: 'Lovelace'
        )

        expect(org).to be_a(AccessGrid::HidOrg)
        expect(org.id).to eq('org_123')
        expect(org.name).to eq('My Org')
        expect(org.slug).to eq('my-org')
        expect(org.first_name).to eq('Ada')
        expect(org.last_name).to eq('Lovelace')
        expect(org.phone).to eq('+1-555-0000')
        expect(org.full_address).to eq('1 Main St, NY NY')
        expect(org.status).to eq('pending')
        expect(org.created_at).to eq('2025-01-01T00:00:00Z')
      end
    end

    describe '#hid.orgs.list' do
      it 'returns a list of HID orgs' do
        list_response = [org_response, org_response.merge(id: 'org_456', name: 'Other Org', slug: 'other-org')]

        stub_api_request(
          :get,
          '/v1/console/hid/orgs',
          body: list_response,
          query: generate_sig_payload(id: :orgs)
        )

        orgs = console.hid.orgs.list

        expect(orgs).to be_an(Array)
        expect(orgs.length).to eq(2)
        expect(orgs.first).to be_a(AccessGrid::HidOrg)
        expect(orgs.first.id).to eq('org_123')
        expect(orgs.last.id).to eq('org_456')
      end

      it 'returns empty array when no orgs' do
        stub_api_request(
          :get,
          '/v1/console/hid/orgs',
          body: [],
          query: generate_sig_payload(id: :orgs)
        )

        orgs = console.hid.orgs.list

        expect(orgs).to eq([])
      end
    end

    describe '#hid.orgs.activate' do
      it 'activates an HID org with credentials' do
        activated_response = org_response.merge(status: 'active')
        request_body = { email: 'admin@example.com', password: 'hid-password-123' }

        stub_api_request(:post, '/v1/console/hid/orgs/activate', body: activated_response, request_body: request_body)

        org = console.hid.orgs.activate(
          email: 'admin@example.com',
          password: 'hid-password-123'
        )

        expect(org).to be_a(AccessGrid::HidOrg)
        expect(org.status).to eq('active')
        expect(org.name).to eq('My Org')
      end
    end
  end
end
