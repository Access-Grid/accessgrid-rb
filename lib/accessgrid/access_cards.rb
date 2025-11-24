# lib/accessgrid/access_cards.rb
module AccessGrid
  class AccessCards
    def initialize(client)
      @client = client
    end

    def issue(params)
      response = @client.make_request(:post, '/v1/key-cards', params)
      Card.new(response)
    end
    
    # Alias provision to issue for backward compatibility
    alias provision issue

    def get(card_id:)
      response = @client.make_request(:get, "/v1/key-cards/#{card_id}")
      Card.new(response)
    end

    def update(card_id, params)
      response = @client.make_request(:patch, "/v1/key-cards/#{card_id}", params)
      Card.new(response)
    end
    
    def list(template_id, state = nil)
      params = { template_id: template_id }
      params[:state] = state if state
      
      response = @client.make_request(:get, '/v1/key-cards', nil, params)
      response.fetch('keys', []).map { |item| Card.new(item) }
    end

    private def manage_state(card_id, action)
      response = @client.make_request(
        :post, 
        "/v1/key-cards/#{card_id}/#{action}", 
        {}
      )
      Card.new(response)
    end

    def suspend(card_id)
      manage_state(card_id, 'suspend')
    end

    def resume(card_id)
      manage_state(card_id, 'resume')
    end

    def unlink(card_id)
      manage_state(card_id, 'unlink')
    end
    
    def delete(card_id)
      manage_state(card_id, 'delete')
    end
  end

  class Card
    attr_reader :id, :state, :url, :install_url, :details, :full_name,
                :expiration_date, :card_template_id, :card_number, :site_code,
                :file_data, :direct_install_url, :devices, :metadata

    def initialize(data)
      data ||= {}
      @id = data.fetch('id', nil)
      @state = data.fetch('state', nil)
      @url = data.fetch('install_url', nil)
      @install_url = data.fetch('install_url', nil)
      @details = data.fetch('details', nil)
      @full_name = data.fetch('full_name', nil)
      @expiration_date = data.fetch('expiration_date', nil)
      @card_template_id = data.fetch('card_template_id', nil)
      @card_number = data.fetch('card_number', nil)
      @site_code = data.fetch('site_code', nil)
      @file_data = data.fetch('file_data', nil)
      @direct_install_url = data.fetch('direct_install_url', nil)
      @devices = data.fetch('devices', [])
      @metadata = data.fetch('metadata', {})
    end

    def to_s
      "Card(name='#{@full_name}', id='#{@id}', state='#{@state}')"
    end

    alias inspect to_s
  end
end