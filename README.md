# ![AccessGrid Logo](accessgrid.png)

AccessGrid is a Ruby SDK for interacting with the [AccessGrid.com](https://www.accessgrid.com) API. This SDK provides a simple interface for managing NFC key cards and enterprise templates. Full docs at https://www.accessgrid.com/docs

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
  tag_id: "DDEADB33FB00B5",
  full_name: "Employee name",
  email: "employee@yourwebsite.com",
  phone_number: "+19547212241",
  classification: "full_time",
  department: "Engineering",
  location: "San Francisco",
  site_name: "HQ Building A",
  workstation: "4F-207",
  mail_stop: "MS-401",
  company_address: "123 Main St, San Francisco, CA 94105",
  start_date: Time.now.utc.iso8601(3),
  expiration_date: 3.months.from_now.utc.iso8601(3),
  employee_photo: "[image_in_base64_encoded_format]",
  title: "Engineering Manager",
  metadata: {
    "department": "engineering",
    "badge_type": "contractor"
  }
)

# Provision is an alias for issue (for backwards compatibility)
card = client.access_cards.provision(
  card_template_id: card_template_id,
  employee_id: "123456789",
  # ...other parameters
)

puts "Install URL: #{card.url}"
```

#### Get a card

```ruby
card = client.access_cards.get(card_id: "0xc4rd1d")

puts "Card ID: #{card.id}"
puts "State: #{card.state}"
puts "Full Name: #{card.full_name}"
puts "Install URL: #{card.install_url}"
puts "Expiration Date: #{card.expiration_date}"
puts "Card Number: #{card.card_number}"
puts "Site Code: #{card.site_code}"
puts "Devices: #{card.devices.length}"
puts "Metadata: #{card.metadata}"
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
  name: "Employee Access Pass",
  platform: "apple",
  use_case: "corporate_id",
  protocol: "desfire",
  allow_on_multiple_devices: true,
  watch_count: 2,
  iphone_count: 3,
  background_color: "#FFFFFF",
  label_color: "#000000",
  label_secondary_color: "#333333",
  support_url: "https://help.yourcompany.com",
  support_phone_number: "+1-555-123-4567",
  support_email: "support@yourcompany.com",
  privacy_policy_url: "https://yourcompany.com/privacy",
  terms_and_conditions_url: "https://yourcompany.com/terms",
  metadata: {
    version: "2.1",
    approval_status: "approved"
  }
)
```

#### Update a template

```ruby
template = client.console.update_template(
  "0xd3adb00b5",
  {
    name: "Updated Employee NFC key",
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

#### Publish a template

```ruby
result = client.console.publish_template("0xd3adb00b5")

puts result.id      # "0xd3adb00b5"
puts result.status  # "in-review" (Apple), "ready" (Android), or "publishing" (already in flight)
```

#### Delete a template

```ruby
client.console.delete_template("0xd3adb00b5")
```

#### Reveal a SmartTap private key

Fetches the template's SmartTap private key, decrypted client-side. The SDK generates a fresh ephemeral P-256 keypair per call, submits the public half, and decrypts the server's response — you get the plaintext PEM back without touching any crypto.

```ruby
reveal = client.console.reveal_smart_tap("0xd3adb00b5")

puts "Key version:  #{reveal.key_version}"
puts "Collector ID: #{reveal.collector_id}"
puts "Fingerprint:  #{reveal.fingerprint}"
puts reveal.private_key  # PEM — store in your reader/collector key vault
```

The server enforces single-use on pubkey fingerprint and rate-limits to 1 per minute per account. The SDK uses a fresh keypair every call, so single-use is satisfied automatically. Errors raised by the crypto path (`AccessGrid::DecryptError`, `AccessGrid::InvalidEnvelopeError`) and the HTTP path (`AccessGrid::AuthenticationError`, `AccessGrid::ResourceNotFoundError`, etc.) all descend from `AccessGrid::Error`.

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

#### List pass template pairs

```ruby
response = client.console.list_pass_template_pairs(page: 1, per_page: 20)

response['card_template_pairs'].each do |pair|
  puts "#{pair.name} (#{pair.id})"
  puts "  iOS: #{pair.ios_template&.name}"
  puts "  Android: #{pair.android_template&.name}"
end

puts response['pagination'] # { "current_page" => 1, "total_pages" => 5, ... }
```

#### List ledger items

```ruby
response = client.console.list_ledger_items(
  page: 1,
  per_page: 50,
  start_date: '2025-01-01T00:00:00Z',
  end_date: '2025-06-30T23:59:59Z'
)

response['ledger_items'].each do |item|
  puts "#{item.kind}: #{item.amount} (#{item.created_at})"

  if item.access_pass
    puts "  Pass: #{item.access_pass.full_name} (#{item.access_pass.state})"
    if item.access_pass.pass_template
      puts "  Template: #{item.access_pass.pass_template.name}"
    end
  end
end

puts response['pagination'] # { "current_page" => 1, "total_pages" => 3, ... }
```

#### iOS In-App Provisioning Preflight

```ruby
response = client.console.ios_preflight(
  card_template_id: "0xt3mp14t3-3x1d",
  access_pass_ex_id: "0xp455-3x1d"
)

puts "Provisioning Credential ID: #{response.provisioning_credential_identifier}"
puts "Sharing Instance ID: #{response.sharing_instance_identifier}"
puts "Card Template ID: #{response.card_template_identifier}"
puts "Environment ID: #{response.environment_identifier}"
```

### Webhooks

#### Create a webhook

```ruby
webhook = client.console.webhooks.create(
  name: 'Production',
  url: 'https://example.com/webhooks',
  subscribed_events: ['ag.access_pass.issued']
)

puts "Webhook created: #{webhook.id}"
puts "Private key: #{webhook.private_key}"
```

#### List webhooks

```ruby
webhooks = client.console.webhooks.list

webhooks.each do |webhook|
  puts "ID: #{webhook.id}, Name: #{webhook.name}"
end
```

#### Delete a webhook

```ruby
client.console.webhooks.delete('abc123')
```

#### Verify a webhook

```ruby
result = client.console.webhooks.verify('abc123')

puts "Verified: #{result.verified}"
```

### HID Organizations

#### Create an HID org

```ruby
org = client.console.hid.orgs.create(
  name: 'My Org',
  full_address: '1 Main St, NY NY',
  phone: '+1-555-0000',
  first_name: 'Ada',
  last_name: 'Lovelace'
)

puts "Created org: #{org.name} (ID: #{org.id})"
puts "Slug: #{org.slug}"
```

#### List HID orgs

```ruby
orgs = client.console.hid.orgs.list

orgs.each do |org|
  puts "Org ID: #{org.id}, Name: #{org.name}, Slug: #{org.slug}"
end
```

#### Activate an HID org

```ruby
result = client.console.hid.orgs.activate(
  email: 'admin@example.com',
  password: 'hid-password-123'
)

puts "Completed registration for org: #{result.name}"
puts "Status: #{result.status}"
```

### Landing Pages

#### List landing pages

```ruby
landing_pages = client.console.list_landing_pages

landing_pages.each do |page|
  puts "ID: #{page.id}, Name: #{page.name}, Kind: #{page.kind}"
  puts "  Password Protected: #{page.password_protected}"
  puts "  Logo URL: #{page.logo_url}" if page.logo_url
end
```

#### Create a landing page

```ruby
landing_page = client.console.create_landing_page(
  name: "Miami Office Access Pass",
  kind: "universal",
  additional_text: "Welcome to the Miami Office",
  bg_color: "#f1f5f9",
  allow_immediate_download: true
)

puts "Landing page created: #{landing_page.id}"
puts "Name: #{landing_page.name}, Kind: #{landing_page.kind}"
```

#### Update a landing page

```ruby
landing_page = client.console.update_landing_page(
  landing_page_id: "0xlandingpage1d",
  name: "Updated Miami Office Access Pass",
  additional_text: "Welcome! Tap below to get your access pass.",
  bg_color: "#e2e8f0"
)

puts "Landing page updated: #{landing_page.id}"
puts "Name: #{landing_page.name}"
```

### Credential Profiles

#### List credential profiles

```ruby
profiles = client.console.credential_profiles.list

profiles.each do |profile|
  puts "ID: #{profile.id}, Name: #{profile.name}, AID: #{profile.aid}"
end
```

#### Create a credential profile

```ruby
profile = client.console.credential_profiles.create(
  name: 'Main Office Profile',
  app_name: 'KEY-ID-main',
  keys: [
    { value: 'your_32_char_hex_master_key_here' },
    { value: 'your_32_char_hex__read_key__here' }
  ]
)

puts "Profile created: #{profile.id}"
puts "AID: #{profile.aid}"
```

#### Delete a credential profile

```ruby
client.console.credential_profiles.delete('a1b2c3d4e5f')
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

- Ruby 2.19 or higher

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

## Feature Matrix

| Endpoint | Method | Supported |
|---|---|:---:|
| POST /v1/key-cards | `access_cards.issue()` | Y |
| GET /v1/key-cards/{id} | `access_cards.get()` | Y |
| PATCH /v1/key-cards/{id} | `access_cards.update()` | Y |
| GET /v1/key-cards | `access_cards.list()` | Y |
| POST /v1/key-cards/{id}/suspend | `access_cards.suspend()` | Y |
| POST /v1/key-cards/{id}/resume | `access_cards.resume()` | Y |
| POST /v1/key-cards/{id}/unlink | `access_cards.unlink()` | Y |
| POST /v1/key-cards/{id}/delete | `access_cards.delete()` | Y |
| POST /v1/console/card-templates | `console.create_template()` | Y |
| PUT /v1/console/card-templates/{id} | `console.update_template()` | Y |
| GET /v1/console/card-templates/{id} | `console.read_template()` | Y |
| GET /v1/console/card-templates/{id}/logs | `console.get_logs()` / `console.event_log()` | Y |
| GET /v1/console/card-template-pairs | `console.list_pass_template_pairs()` | Y |
| POST /v1/console/card-template-pairs | `console.create_pass_template_pair()` | Y |
| POST /v1/console/card-templates/{id}/ios_preflight | `console.ios_preflight()` | Y |
| POST /v1/console/card-templates/{id}/publish | `console.publish_template()` | Y |
| POST /v1/console/card-templates/{id}/smart-tap/reveal | `console.reveal_smart_tap()` | Y |
| DELETE /v1/console/card-templates/{id} | `console.delete_template()` | Y |
| GET /v1/console/ledger-items | `console.list_ledger_items()` / `console.ledger_items()` | Y |
| GET /v1/console/webhooks | `console.webhooks.list()` | Y |
| POST /v1/console/webhooks | `console.webhooks.create()` | Y |
| DELETE /v1/console/webhooks/{id} | `console.webhooks.delete()` | Y |
| POST /v1/console/webhooks/{id}/verify | `console.webhooks.verify()` | Y |
| GET /v1/console/landing-pages | `console.list_landing_pages()` | Y |
| POST /v1/console/landing-pages | `console.create_landing_page()` | Y |
| PUT /v1/console/landing-pages/{id} | `console.update_landing_page()` | Y |
| GET /v1/console/credential-profiles | `console.credential_profiles.list()` | Y |
| POST /v1/console/credential-profiles | `console.credential_profiles.create()` | Y |
| DELETE /v1/console/credential-profiles/{id} | `console.credential_profiles.delete()` | Y |
| POST /v1/console/hid/orgs | `console.hid.orgs.create()` | Y |
| POST /v1/console/hid/orgs/activate | `console.hid.orgs.activate()` | Y |
| GET /v1/console/hid/orgs | `console.hid.orgs.list()` | Y |

## License

The gem is available as open source under the terms of the MIT License.
