require 'rails_helper'

RSpec.describe 'Refresh Tokens API', type: :request do
  describe 'POST /users/refresh-token' do
    it 'rotates the refresh token and returns a new access token and refresh token' do
      user = create(:user)
      rt = create(:refresh_token, user: user)

      # Stub JWT generation to avoid depending on Warden internals in this test
      allow_any_instance_of(Users::RefreshTokensController).to receive(:generate_jwt_token).and_return('fake_jwt_token')

      post '/users/refresh-token', params: { refresh_token: rt.token }.to_json, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data']).to be_a(Hash)
      expect(body['data']['token']).to eq('fake_jwt_token')
      expect(body['data']['refresh_token']).to be_present

      rt.reload
      expect(rt.revoked_at).to be_present
      # Ensure a new refresh token was created for the user
      expect(user.refresh_tokens.active.count).to be >= 1
    end

    it 'returns 401 for an invalid refresh token' do
      post '/users/refresh-token', params: { refresh_token: 'nope' }.to_json, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body['message']).to match(/Invalid or expired refresh token/i)
    end

    it 'returns 401 for an expired refresh token' do
  user = create(:user)
  expired_rt = create(:refresh_token, user: user)
  # before_create in the model sets expires_at; override it in DB to simulate expiration
  expired_rt.update_column(:expires_at, 2.days.ago)

  post '/users/refresh-token', params: { refresh_token: expired_rt.token }.to_json, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body['message']).to match(/Invalid or expired refresh token/i)
    end
  end
end
