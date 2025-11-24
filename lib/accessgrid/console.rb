# lib/accessgrid/console.rb
module AccessGrid
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
      if response['logs']
        response['logs'] = response['logs'].map { |log| Event.new(log) }
      end
      
      response
    end
    
    # Keep event_log for backwards compatibility
    def event_log(params)
      template_id = params.delete(:card_template_id)
      response = get_logs(template_id, params)
      response['logs'] || []
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

  class Event
    attr_reader :type, :timestamp, :user_id, :ip_address, :user_agent, :metadata

    def initialize(data)
      @type = data['event']
      @timestamp = data['created_at']
      @user_id = data['metadata']['user_id'] if data['metadata'] && data['metadata']['user_id']
      @ip_address = data['ip_address']
      @user_agent = data['user_agent']
      @metadata = data['metadata']
    end
  end
end