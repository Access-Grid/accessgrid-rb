# frozen_string_literal: true

# accessgrid.gemspec
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'accessgrid/version'

Gem::Specification.new do |spec|
  spec.name          = 'accessgrid'
  spec.version       = AccessGrid::VERSION
  spec.authors       = ['Auston Bunsen']
  spec.email         = ['ab@accessgrid.com']
  spec.summary       = 'AccessGrid API Client'
  spec.description   = 'A Ruby client for the AccessGrid API'
  spec.homepage      = 'https://github.com/access-grid/accessgrid-rb'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata      = { 'source_code_uri' => 'https://github.com/access-grid/accessgrid-rb' }

  # Specify which files should be added to the gem when it is released
  spec.files         = Dir['lib/**/*', 'README.md', 'LICENSE', 'CHANGELOG.md']
  spec.bindir        = 'bin'
  spec.executables   = []
  spec.require_paths = ['lib']

  spec.add_dependency 'base64'
end
