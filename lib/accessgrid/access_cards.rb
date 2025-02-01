# lib/accessgrid/access_cards.rb
module AccessGrid
  class AccessCards
    def initialize(client)
      @client = client
    end

    def provision(params)
      response = @client.make_request(:post, '/api/v1/nfc_keys/issue', params)
      Card.new(response)
    end

    def update(params)
      card_id = params.delete(:card_id)
      response = @client.make_request(:put, "/api/v1/nfc_keys/#{card_id}", params)
      Card.new(response)
    end

    private def manage_state(card_id, action)
      response = @client.make_request(
        :post, 
        "/api/v1/nfc_keys/#{card_id}/manage", 
        { manage_action: action }
      )
      Card.new(response)
    end

    def suspend(params)
      manage_state(params[:card_id], 'suspend')
    end

    def resume(params)
      manage_state(params[:card_id], 'resume')
    end

    def unlink(params)
      manage_state(params[:card_id], 'unlink')
    end
  end

  class Card
    attr_reader :id, :state, :url, :full_name, :expiration_date

    def initialize(data)
      @id = data['id']
      @state = data['state']
      @url = data['install_url']
      @full_name = data['full_name']
      @expiration_date = data['expiration_date']
    end
  end
end