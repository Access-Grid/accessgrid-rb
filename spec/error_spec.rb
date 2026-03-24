# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessGrid::Error do
  it 'inherits from StandardError' do
    expect(described_class).to be < StandardError
  end

  it 'can be instantiated with a message' do
    error = described_class.new('Something went wrong')
    expect(error.message).to eq('Something went wrong')
  end
end

RSpec.describe AccessGrid::AuthenticationError do
  it 'inherits from AccessGrid::Error' do
    expect(described_class).to be < AccessGrid::Error
  end
end

RSpec.describe AccessGrid::ResourceNotFoundError do
  it 'inherits from AccessGrid::Error' do
    expect(described_class).to be < AccessGrid::Error
  end
end

RSpec.describe AccessGrid::ValidationError do
  it 'inherits from AccessGrid::Error' do
    expect(described_class).to be < AccessGrid::Error
  end
end

RSpec.describe AccessGrid::AccessGridError do
  it 'inherits from AccessGrid::Error' do
    expect(described_class).to be < AccessGrid::Error
  end
end
