require 'rails_helper'

RSpec.describe 'Refresh Tokens E2E', type: :request do
  describe 'full login -> refresh flow' do
    it 'logs in, receives refresh token, and can rotate it to get new tokens' do
      password = 'Password123!@'
      user = create(:user, password: password, password_confirmation: password, confirmed_at: Time.current)

  # Login to get JWT and refresh token (Devise expects params under :user)
  post '/login', params: { user: { email: user.email, password: password } }.to_json, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['token']).to be_present
      expect(body['refresh_token']).to be_present

      original_refresh_token = body['refresh_token']
      expect(user.refresh_tokens.find_by(token: original_refresh_token)).to be_present

      # Call refresh-token endpoint with the real refresh token (no stubbing)
      post '/users/refresh-token', params: { refresh_token: original_refresh_token }.to_json, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

      expect(response).to have_http_status(:ok)
      new_body = JSON.parse(response.body)
      expect(new_body['data']).to be_a(Hash)
      expect(new_body['data']['token']).to be_present
      expect(new_body['data']['refresh_token']).to be_present

      user.reload
      # Original token should be revoked
      expect(user.refresh_tokens.where(token: original_refresh_token).first.revoked_at).to be_present
      # New token should exist and be active
      expect(user.refresh_tokens.where(token: new_body['data']['refresh_token']).first).to be_present
    end
  end
end
