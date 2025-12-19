# AccessGrid SDK

A Ruby SDK for interacting with the [AccessGrid.com](https://www.accessgrid.com) API. This SDK provides a simple interface for managing NFC key cards and enterprise templates. Full docs at https://www.accessgrid.com/docs

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'accessgrid'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install accessgrid
```

## Quick Start

```ruby
require 'accessgrid'

account_id = ENV['ACCOUNT_ID']
secret_key = ENV['SECRET_KEY']

client = AccessGrid.new(account_id, secret_key)
```

## API Reference

### Access Cards

#### Issue a new card

```ruby
card = client.access_cards.issue(
  card_template_id: card_template_id,
  employee_id: "123456789",
  card_number: "16187",
  tag_id: "DDEADB33FB00B5",
  full_name: "Employee name",
  email: "employee@yourwebsite.com",
  phone_number: "+19547212241",
  classification: "full_time",
  start_date: "2025-01-31T22:46:25.601Z",
  expiration_date: "2025-04-30T22:46:25.601Z",
  employee_photo: "[image_in_base64_encoded_format]"
)

# Provision is an alias for issue (for backwards compatibility)
card = client.access_cards.provision(
  card_template_id: card_template_id,
  employee_id: "123456789",
  # ...other parameters
)

puts "Install URL: #{card.url}"
```

#### UnifiedAccessPass (Template Pairs)

When issuing a card to a template pair (combined Apple + Android templates), the API returns a `UnifiedAccessPass` instead of a single `Card`. The SDK automatically detects this and returns the appropriate type.

```ruby
# Issue to a template pair
result = client.access_cards.issue(
  card_template_id: template_pair_id,
  employee_id: "123456789",
  full_name: "Employee name",
  # ...other parameters
)

# Check which type was returned
if result.unified_access_pass?
  # UnifiedAccessPass contains both Apple and Android cards
  puts "UnifiedAccessPass ID: #{result.id}"
  puts "State: #{result.state}"
  puts "Status: #{result.status}"
  puts "Install URL: #{result.url}"
  puts "Number of cards: #{result.details.length}"

  # Access individual cards in the details array
  result.details.each do |card|
    puts "  Card ID: #{card.id}"
    puts "  Card Template: #{card.card_template_id}"
    puts "  State: #{card.state}"
  end
elsif result.card?
  # Single card response
  puts "Card ID: #{result.id}"
  puts "Install URL: #{result.url}"
end
```

Both `Card` and `UnifiedAccessPass` inherit from `Union` and share common properties:
- `id` - The unique identifier
- `url` / `install_url` - The installation URL
- `state` - Current state of the pass

#### Get a card or pass

The `get` method returns either a `Card` or `UnifiedAccessPass` depending on the ID provided.

```ruby
result = client.access_cards.get(card_id: "0xc4rd1d")

if result.card?
  puts "Card ID: #{result.id}"
  puts "State: #{result.state}"
  puts "Full Name: #{result.full_name}"
  puts "Install URL: #{result.install_url}"
  puts "Expiration Date: #{result.expiration_date}"
  puts "Card Number: #{result.card_number}"
  puts "Site Code: #{result.site_code}"
  puts "Devices: #{result.devices.length}"
  puts "Metadata: #{result.metadata}"
elsif result.unified_access_pass?
  puts "UnifiedAccessPass ID: #{result.id}"
  puts "Cards: #{result.details.length}"
end
```

#### Update a card

```ruby
card = client.access_cards.update(
  "0xc4rd1d", 
  {
    employee_id: "987654321",
    full_name: "Updated Employee Name",
    classification: "contractor",
    expiration_date: "2025-02-22T21:04:03.664Z",
    employee_photo: "[image_in_base64_encoded_format]"
  }
)
```

#### List cards

```ruby
# List all cards for a template
cards = client.access_cards.list("template_id")

# List cards filtered by state
active_cards = client.access_cards.list("template_id", "active")
```

#### Manage card states

```ruby
# Suspend a card
client.access_cards.suspend("0xc4rd1d")

# Resume a card
client.access_cards.resume("0xc4rd1d")

# Unlink a card
client.access_cards.unlink("0xc4rd1d")

# Delete a card
client.access_cards.delete("0xc4rd1d")
```

### Enterprise Console

#### Create a template

```ruby
template = client.console.create_template(
  name: "Employee NFC key",
  platform: "apple",
  use_case: "employee_badge",
  protocol: "desfire",
  allow_on_multiple_devices: true,
  watch_count: 2,
  iphone_count: 3,
  design: {
    background_color: "#FFFFFF",
    label_color: "#000000",
    label_secondary_color: "#333333",
    background_image: "[image_in_base64_encoded_format]",
    logo_image: "[image_in_base64_encoded_format]",
    icon_image: "[image_in_base64_encoded_format]"
  },
  support_info: {
    support_url: "https://help.yourcompany.com",
    support_phone_number: "+1-555-123-4567",
    support_email: "support@yourcompany.com",
    privacy_policy_url: "https://yourcompany.com/privacy",
    terms_and_conditions_url: "https://yourcompany.com/terms"
  }
)
```

#### Update a template

```ruby
template = client.console.update_template(
  "0xd3adb00b5",
  {
    name: "Updated Employee NFC key",
    allow_on_multiple_devices: true,
    watch_count: 2,
    iphone_count: 3,
    support_info: {
      support_url: "https://help.yourcompany.com",
      support_phone_number: "+1-555-123-4567",
      support_email: "support@yourcompany.com",
      privacy_policy_url: "https://yourcompany.com/privacy",
      terms_and_conditions_url: "https://yourcompany.com/terms"
    }
  }
)
```

#### Read a template

```ruby
template = client.console.read_template("0xd3adb00b5")
```

#### Get event logs

```ruby
# New method
logs = client.console.get_logs(
  "0xd3adb00b5",
  {
    device: "mobile", # "mobile" or "watch"
    start_date: (Time.now - 30*24*60*60).iso8601,
    end_date: Time.now.iso8601,
    event_type: "install"
  }
)

# Legacy method still works
events = client.console.event_log(
  card_template_id: "0xd3adb00b5",
  filters: {
    device: "mobile", # "mobile" or "watch"
    start_date: (Time.now - 30*24*60*60).iso8601,
    end_date: Time.now.iso8601,
    event_type: "install"
  }
)
```

## Configuration

The SDK can be configured with a custom API endpoint:

```ruby
client = AccessGrid.new(
  account_id, 
  secret_key, 
  'https://api.staging.accessgrid.com' # Use a different API endpoint
)
```

## Error Handling

The SDK throws specific errors for various scenarios:
- `AccessGrid::AuthenticationError` - Invalid credentials
- `AccessGrid::ResourceNotFoundError` - Requested resource not found
- `AccessGrid::ValidationError` - Invalid parameters
- `AccessGrid::AccessGridError` - Base exception for AccessGrid-specific errors
- `AccessGrid::Error` - Generic API errors

Example error handling:

```ruby
begin
  card = client.access_cards.provision(
    # ... parameters
  )
rescue AccessGrid::ValidationError => e
  puts "Invalid parameters: #{e.message}"
rescue AccessGrid::Error => e
  puts "API error: #{e.message}"
end
```

## Requirements

- Ruby 2.6 or higher

## Security

The SDK automatically handles:
- Request signing using HMAC-SHA256
- Secure payload encoding
- Authentication headers
- HTTPS communication

Never expose your `secret_key` in client-side code. Always use environment variables or a secure configuration management system.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/access-grid/accessgrid-rb.

## License

The gem is available as open source under the terms of the MIT License.