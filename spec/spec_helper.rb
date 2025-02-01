# spec/spec_helper.rb
require 'bundler/setup'
require 'webmock/rspec'
require 'accessgrid'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random
  Kernel.srand config.seed
end

def stub_api_request(method, path, status: 200, body: {}, request_body: nil)
  stub = stub_request(method, "https://api.accessgrid.com#{path}")
    .with(
      headers: {
        'Content-Type' => 'application/json',
        'X-ACCT-ID' => 'test_account'
      }
    )
  
  # Add request body validation if provided
  if request_body
    stub.with(body: request_body)
  end

  stub.to_return(
    status: status,
    body: body.to_json,
    headers: { 'Content-Type' => 'application/json' }
  )
end