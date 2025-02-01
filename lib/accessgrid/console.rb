# lib/accessgrid/console.rb
module AccessGrid
  class Console
    def initialize(client)
      @client = client
    end

    def create_template(params)
      transformed_params = transform_template_params(params)
      response = @client.make_request(:post, '/api/v1/enterprise/templates', transformed_params)
      Template.new(response)
    end

    def update_template(params)
      card_template_id = params.delete(:card_template_id)
      transformed_params = transform_template_params(params)
      response = @client.make_request(:put, "/api/v1/enterprise/templates/#{card_template_id}", transformed_params)
      Template.new(response)
    end

    def read_template(params)
      response = @client.make_request(:get, "/api/v1/enterprise/templates/#{params[:card_template_id]}")
      Template.new(response)
    end

    def event_log(params)
      card_template_id = params.delete(:card_template_id)
      response = @client.make_request(:get, "/api/v1/enterprise/templates/#{card_template_id}/logs", params)
      response['logs'].map { |log| Event.new(log) }
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
    attr_reader :id, :name, :platform, :protocol, :allow_on_multiple_devices,
                :watch_count, :iphone_count, :support_info, :style_settings

    def initialize(data)
      @id = data['id']
      @name = data['name']
      @platform = data['platform']
      @protocol = data['protocol']
      @allow_on_multiple_devices = data['allowed_device_counts']['allow_on_multiple_devices']
      @watch_count = data['allowed_device_counts']['watch']
      @iphone_count = data['allowed_device_counts']['iphone']
      @support_info = data['support_settings']
      @style_settings = data['style_settings']
    end
  end

  class Event
    attr_reader :type, :timestamp, :user_id, :ip_address, :user_agent, :metadata

    def initialize(data)
      @type = data['event']
      @timestamp = data['created_at']
      @user_id = data['metadata']['user_id']
      @ip_address = data['ip_address']
      @user_agent = data['user_agent']
      @metadata = data['metadata']
    end
  end
end