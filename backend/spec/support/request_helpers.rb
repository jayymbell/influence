# frozen_string_literal: true

module RequestHelpers
  def json_headers
    { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
  end

  def json_response
    JSON.parse(response.body)
  end

  def valid_password
    'Password123!@'
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
