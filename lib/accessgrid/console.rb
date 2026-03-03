# frozen_string_literal: true

# lib/accessgrid/console.rb
module AccessGrid
  # Manages enterprise template and logging operations.
  class Console
    def initialize(client)
      @client = client
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

    private

    def transform_template_params(params)
      design = params.delete(:design) || {}
      support_info = params.delete(:support_info) || {}

      params.merge(
        background_color: design[:background_color],
        label_color: design[:label_color],
        label_secondary_color: design[:label_secondary_color],
        support_url: support_info[:support_url],
        support_phone_number: support_info[:support_phone_number],
        support_email: support_info[:support_email],
        privacy_policy_url: support_info[:privacy_policy_url],
        terms_and_conditions_url: support_info[:terms_and_conditions_url]
      )
    end
  end

  # Represents a card template configuration.
  class Template
    attr_reader :id, :name, :platform, :protocol, :use_case, :created_at,
                :last_published_at, :issued_keys_count, :active_keys_count,
                :allowed_device_counts, :support_settings, :terms_settings, :style_settings

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

  # Represents a billing ledger item.
  class LedgerItem
    attr_reader :created_at, :amount, :id, :kind, :metadata, :access_pass

    def initialize(data)
      @created_at = data['created_at']
      @amount = data['amount']
      @id = data['ex_id']
      @kind = data['kind']
      @metadata = data['metadata']
      @access_pass = data['access_pass'] ? LedgerItemAccessPass.new(data['access_pass']) : nil
    end
  end

  # Represents an access pass reference within a ledger item.
  class LedgerItemAccessPass
    attr_reader :id, :full_name, :state, :metadata, :unified_access_pass_ex_id, :pass_template

    def initialize(data)
      @id = data['ex_id']
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
      @id = data['ex_id']
      @name = data['name']
      @protocol = data['protocol']
      @platform = data['platform']
      @use_case = data['use_case']
    end
  end
end
