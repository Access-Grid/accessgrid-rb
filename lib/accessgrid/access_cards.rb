# lib/accessgrid/access_cards.rb
module AccessGrid
  class AccessCards
    def initialize(client)
      @client = client
    end

    def issue(params)
      response = @client.make_request(:post, '/v1/key-cards', params)
      Union.from_response(response)
    end

    # Alias provision to issue for backward compatibility
    alias provision issue

    def get(card_id:)
      response = @client.make_request(:get, "/v1/key-cards/#{card_id}")
      Union.from_response(response)
    end

    def update(card_id, params)
      response = @client.make_request(:patch, "/v1/key-cards/#{card_id}", params)
      Union.from_response(response)
    end

    def list(card_template_id, state = nil)
      params = { card_template_id: card_template_id }
      params[:state] = state if state

      response = @client.make_request(:get, '/v1/key-cards', nil, params)
      response.fetch('keys', []).map { |item| Union.from_response(item) }
    end

    private def manage_state(card_id, action)
      response = @client.make_request(
        :post,
        "/v1/key-cards/#{card_id}/#{action}",
        {}
      )
      Union.from_response(response)
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

  # Abstract base class for AccessCard and UnifiedAccessPass
  # Both types share common properties: id, url, state
  class Union
    attr_reader :id, :state, :url

    def initialize(data)
      data ||= {}
      @id = data.fetch('id', nil)
      @state = data.fetch('state', nil)
      @url = data.fetch('install_url', nil)
    end

    # Factory method to create the appropriate type based on response
    # If response has a non-null 'details' array, return UnifiedAccessPass
    # Otherwise, return Card
    def self.from_response(data)
      data ||= {}
      if data['details'].is_a?(Array) && !data['details'].empty?
        UnifiedAccessPass.new(data)
      else
        Card.new(data)
      end
    end

    def unified_access_pass?
      false
    end

    def card?
      false
    end
  end

  class Card < Union
    attr_reader :full_name, :expiration_date, :card_template_id, :card_number,
                :site_code, :file_data, :direct_install_url, :devices, :metadata

    def initialize(data)
      super(data)
      data ||= {}
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

    def card?
      true
    end

    def to_s
      "Card(name='#{@full_name}', id='#{@id}', state='#{@state}')"
    end

    alias inspect to_s
  end

  # UnifiedAccessPass represents a template pair response containing
  # both Apple and Android cards in the details array
  class UnifiedAccessPass < Union
    attr_reader :status, :details

    def initialize(data)
      super(data)
      data ||= {}
      @status = data.fetch('status', nil)
      @details = (data.fetch('details', []) || []).map { |card_data| Card.new(card_data) }
    end

    def unified_access_pass?
      true
    end

    def to_s
      "UnifiedAccessPass(id='#{@id}', state='#{@state}', status='#{@status}', cards=#{@details.length})"
    end

    alias inspect to_s
  end
end