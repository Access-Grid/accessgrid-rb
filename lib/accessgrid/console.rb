# frozen_string_literal: true

# lib/accessgrid/console.rb
module AccessGrid
  # Manages enterprise template and logging operations.
  class Console
    attr_reader :webhooks, :hid, :credential_profiles

    def initialize(client)
      @client = client
      @webhooks = Webhooks.new(client)
      @hid = HID.new(client)
      @credential_profiles = CredentialProfiles.new(client)
    end

    def create_template(params)
      transformed_params = transform_template_params(params)
      response = @client.make_request(:post, '/v1/console/card-templates', transformed_params)
      Template.new(response)
    end

    def update_template(template_id, params)
      transformed_params = transform_template_params(params)
      response = @client.make_request(:put, "/v1/console/card-templates/#{template_id}", transformed_params)
      Template.new(response)
    end

    def read_template(template_id)
      response = @client.make_request(:get, "/v1/console/card-templates/#{template_id}")
      Template.new(response)
    end

    def get_logs(template_id, params = {})
      response = @client.make_request(:get, "/v1/console/card-templates/#{template_id}/logs", nil, params)

      # Return full response to match Python's behavior
      response['logs'] = response['logs'].map { |log| Event.new(log) } if response['logs']

      response
    end

    # Keep event_log for backwards compatibility
    def event_log(params)
      template_id = params.delete(:card_template_id)
      response = get_logs(template_id, params)
      response['logs'] || []
    end

    def list_pass_template_pairs(params = {})
      response = @client.make_request(:get, '/v1/console/pass-template-pairs', nil, params)

      if response['pass_template_pairs']
        response['pass_template_pairs'] = response['pass_template_pairs'].map { |pair| PassTemplatePair.new(pair) }
      end

      response
    end

    def list_ledger_items(params = {})
      response = @client.make_request(:get, '/v1/console/ledger-items', nil, params)

      if response['ledger_items']
        response['ledger_items'] = response['ledger_items'].map { |item| LedgerItem.new(item) }
      end

      response
    end

    alias ledger_items list_ledger_items

    def ios_preflight(card_template_id:, access_pass_ex_id:)
      data = { access_pass_ex_id: access_pass_ex_id }
      response = @client.make_request(:post, "/v1/console/card-templates/#{card_template_id}/ios_preflight", data)
      IosPreflight.new(response)
    end

    def list_landing_pages
      response = @client.make_request(:get, '/v1/console/landing-pages')
      pages = response.is_a?(Array) ? response : response.fetch('landing_pages', [])
      pages.map { |page| LandingPage.new(page) }
    end

    def create_landing_page(**params)
      response = @client.make_request(:post, '/v1/console/landing-pages', params)
      LandingPage.new(response)
    end

    def update_landing_page(landing_page_id:, **params)
      response = @client.make_request(:put, "/v1/console/landing-pages/#{landing_page_id}", params)
      LandingPage.new(response)
    end

    private

    def transform_template_params(params)
      design = params.delete(:design)
      support_info = params.delete(:support_info)

      # Only merge nested keys if they were provided (backward compat)
      params.merge!(design) if design
      params.merge!(support_info) if support_info

      params
    end
  end

  # Represents a card template configuration.
  class Template
    attr_reader :id, :name, :platform, :protocol, :use_case, :created_at,
                :last_published_at, :issued_keys_count, :active_keys_count,
                :allowed_device_counts, :support_settings, :terms_settings, :style_settings,
                :metadata

    def initialize(data)
      @id = data['id']
      @name = data['name']
      @platform = data['platform']
      @protocol = data['protocol']
      @use_case = data['use_case']
      @created_at = data['created_at']
      @last_published_at = data['last_published_at']
      @issued_keys_count = data['issued_keys_count']
      @active_keys_count = data['active_keys_count']
      @allowed_device_counts = data['allowed_device_counts']
      @support_settings = data['support_settings']
      @terms_settings = data['terms_settings']
      @style_settings = data['style_settings']
      @metadata = data['metadata'] || {}
    end
  end

  # Represents a template activity log event.
  class Event
    attr_reader :type, :timestamp, :user_id, :ip_address, :user_agent, :metadata

    def initialize(data)
      metadata = data['metadata']
      @type = data['event']
      @timestamp = data['created_at']
      @user_id = metadata['user_id'] if metadata && metadata['user_id']
      @ip_address = data['ip_address']
      @user_agent = data['user_agent']
      @metadata = metadata
    end
  end

  # Represents a paired iOS and Android template configuration.
  class PassTemplatePair
    attr_reader :id, :name, :created_at, :android_template, :ios_template

    def initialize(data)
      android_template = data['android_template']
      ios_template = data['ios_template']
      @id = data['id']
      @name = data['name']
      @created_at = data['created_at']
      @android_template = android_template ? TemplateInfo.new(android_template) : nil
      @ios_template = ios_template ? TemplateInfo.new(ios_template) : nil
    end
  end

  # Minimal template info used within PassTemplatePair.
  class TemplateInfo
    attr_reader :id, :name, :platform

    def initialize(data)
      @id = data['id']
      @name = data['name']
      @platform = data['platform']
    end
  end

  # Represents an iOS In-App Provisioning preflight response.
  class IosPreflight
    attr_reader :provisioning_credential_identifier, :sharing_instance_identifier,
                :card_template_identifier, :environment_identifier

    def initialize(data)
      @provisioning_credential_identifier = data['provisioningCredentialIdentifier']
      @sharing_instance_identifier = data['sharingInstanceIdentifier']
      @card_template_identifier = data['cardTemplateIdentifier']
      @environment_identifier = data['environmentIdentifier']
    end
  end

  # Represents a billing ledger item.
  class LedgerItem
    attr_reader :created_at, :amount, :id, :kind, :metadata, :access_pass

    def initialize(data)
      @created_at = data['created_at']
      @amount = data['amount']
      @id = data['id']
      @kind = data['kind']
      @metadata = data['metadata']
      @access_pass = data['access_pass'] ? LedgerItemAccessPass.new(data['access_pass']) : nil
    end
  end

  # Represents an access pass reference within a ledger item.
  class LedgerItemAccessPass
    attr_reader :id, :full_name, :state, :metadata, :unified_access_pass_ex_id, :pass_template

    def initialize(data)
      @id = data['id']
      @full_name = data['full_name']
      @state = data['state']
      @metadata = data['metadata']
      @unified_access_pass_ex_id = data['unified_access_pass_ex_id']
      @pass_template = data['pass_template'] ? LedgerItemPassTemplate.new(data['pass_template']) : nil
    end
  end

  # Represents a pass template reference within a ledger item's access pass.
  class LedgerItemPassTemplate
    attr_reader :id, :name, :protocol, :platform, :use_case

    def initialize(data)
      @id = data['id']
      @name = data['name']
      @protocol = data['protocol']
      @platform = data['platform']
      @use_case = data['use_case']
    end
  end

  # Represents a landing page configuration.
  class LandingPage
    attr_reader :id, :name, :created_at, :kind, :password_protected, :logo_url

    def initialize(data)
      @id = data['id']
      @name = data['name']
      @created_at = data['created_at']
      @kind = data['kind']
      @password_protected = data['password_protected']
      @logo_url = data['logo_url']
    end
  end

  # Represents a credential profile configuration.
  class CredentialProfile
    attr_reader :id, :aid, :name, :apple_id, :created_at, :card_storage, :keys, :files

    def initialize(data)
      @id = data['id']
      @aid = data['aid']
      @name = data['name']
      @apple_id = data['apple_id']
      @created_at = data['created_at']
      @card_storage = data['card_storage']
      @keys = data['keys'] || []
      @files = data['files'] || []
    end
  end

  # Manages credential profile operations.
  class CredentialProfiles
    def initialize(client)
      @client = client
    end

    def create(**params)
      response = @client.make_request(:post, '/v1/console/credential-profiles', params)
      CredentialProfile.new(response)
    end

    def list
      response = @client.make_request(:get, '/v1/console/credential-profiles')
      profiles = response.is_a?(Array) ? response : response.fetch('credential_profiles', [])
      profiles.map { |profile| CredentialProfile.new(profile) }
    end
  end

  # Manages webhook operations.
  class Webhooks
    def initialize(client)
      @client = client
    end

    def create(name:, url:, subscribed_events:, auth_method: 'bearer_token')
      data = {
        name: name,
        url: url,
        subscribed_events: subscribed_events,
        auth_method: auth_method
      }
      response = @client.make_request(:post, '/v1/console/webhooks', data)
      Webhook.new(response)
    end

    def list(**params)
      response = @client.make_request(:get, '/v1/console/webhooks', nil, params)
      (response['webhooks'] || []).map { |wh| Webhook.new(wh) }
    end

    def delete(webhook_id)
      @client.make_request(:delete, "/v1/console/webhooks/#{webhook_id}")
    end
  end

  # Represents a webhook configuration.
  class Webhook
    attr_reader :id, :name, :url, :auth_method, :subscribed_events,
                :created_at, :private_key, :client_cert, :cert_expires_at

    def initialize(data)
      @id = data['id']
      @name = data['name']
      @url = data['url']
      @auth_method = data['auth_method']
      @subscribed_events = data['subscribed_events']
      @created_at = data['created_at']
      @private_key = data['private_key']
      @client_cert = data['client_cert']
      @cert_expires_at = data['cert_expires_at']
    end
  end

  # Provides access to HID-related services.
  class HID
    attr_reader :orgs

    def initialize(client)
      @orgs = HIDOrgs.new(client)
    end
  end

  # Manages HID organization operations.
  class HIDOrgs
    def initialize(client)
      @client = client
    end

    def create(name:, full_address:, phone:, first_name:, last_name:)
      data = {
        name: name,
        full_address: full_address,
        phone: phone,
        first_name: first_name,
        last_name: last_name
      }
      response = @client.make_request(:post, '/v1/console/hid/orgs', data)
      HidOrg.new(response)
    end

    def list
      response = @client.make_request(:get, '/v1/console/hid/orgs')
      response.map { |org| HidOrg.new(org) }
    end

    def activate(email:, password:)
      data = { email: email, password: password }
      response = @client.make_request(:post, '/v1/console/hid/orgs/activate', data)
      HidOrg.new(response)
    end
  end

  # Represents an HID organization.
  class HidOrg
    attr_reader :id, :name, :slug, :first_name, :last_name, :phone, :full_address, :status, :created_at

    def initialize(data)
      @id = data['id']
      @name = data['name']
      @slug = data['slug']
      @first_name = data['first_name']
      @last_name = data['last_name']
      @phone = data['phone']
      @full_address = data['full_address']
      @status = data['status']
      @created_at = data['created_at']
    end
  end
end
