# frozen_string_literal: true
require 'rails_helper'

RSpec.describe JwtClaimsService, type: :service do
  describe '.call' do
    it 'returns a hash with expected JWT claim keys' do
      user = double('User', id: 42)
      request = double('Request', remote_ip: '127.0.0.1', user_agent: 'RSpec')

      claims = described_class.call(user, request)

      expect(claims).to include(:iat, :jti, :iss, :sub, :ip, :ua)
      expect(claims[:sub]).to eq(42)
      expect(claims[:ip]).to eq('127.0.0.1')
      expect(claims[:ua]).to eq('RSpec')
    end
  end
end
