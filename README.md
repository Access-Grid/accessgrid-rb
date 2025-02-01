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

#### Provision a new card

```ruby
card = client.access_cards.provision(
  card_template_id: "0xd3adb00b5",
  employee_id: "123456789",
  tag_id: "DDEADB33FB00B5",
  allow_on_multiple_devices: true,
  full_name: "Employee name",
  email: "employee@yourwebsite.com",
  phone_number: "+19547212241",
  classification: "full_time",
  start_date: "2025-01-31T22:46:25.601Z",
  expiration_date: "2025-04-30T22:46:25.601Z",
  employee_photo: "[image_in_base64_encoded_format]"
)

puts "Install URL: #{card.url}"
```

#### Update a card

```ruby
card = client.access_cards.update(
  card_id: "0xc4rd1d",
  employee_id: "987654321",
  full_name: "Updated Employee Name",
  classification: "contractor",
  expiration_date: "2025-02-22T21:04:03.664Z",
  employee_photo: "[image_in_base64_encoded_format]"
)
```

#### Manage card states

```ruby
# Suspend a card
client.access_cards.suspend(
  card_id: "0xc4rd1d"
)

# Resume a card
client.access_cards.resume(
  card_id: "0xc4rd1d"
)

# Unlink a card
client.access_cards.unlink(
  card_id: "0xc4rd1d"
)
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
  card_template_id: "0xd3adb00b5",
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
)
```

#### Read a template

```ruby
template = client.console.read_template(
  card_template_id: "0xd3adb00b5"
)
```

#### Get event logs

```ruby
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

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/accessgrid-ruby.

## License

The gem is available as open source under the terms of the MIT License.