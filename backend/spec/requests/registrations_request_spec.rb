require 'rails_helper'

RSpec.describe 'Registrations API', type: :request do
  let(:headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }
  let(:valid_password) { 'Password123!@' }

  before do
    ActionMailer::Base.deliveries.clear
    # Clear Rack::Attack cache to avoid test flakiness from rate limits
    Rack::Attack.cache.store.clear if defined?(Rack::Attack)
  end

  describe 'POST /signup' do
    it 'creates a user and enqueues confirmation email' do
      post '/signup', params: { user: { email: 'new@example.com', password: valid_password, password_confirmation: valid_password } }.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['message']).to be_present

      user = User.find_by(email: 'new@example.com')
      expect(user).not_to be_nil
      # Confirmable: user should be unconfirmed after sign up
      expect(user.confirmed_at).to be_nil

      # Confirmation email should have been sent
      expect(ActionMailer::Base.deliveries.size).to be >= 1
    end

    it 'returns 422 when password is weak' do
      post '/signup', params: { user: { email: 'weak@example.com', password: 'weak', password_confirmation: 'weak' } }.to_json, headers: headers

  expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body['errors']).to be_present
      expect(body['errors'].join(' ')).to match(/must contain at least one uppercase letter|too short|must contain at least one special character/i)
    end

    it 'returns 422 when email already exists' do
      create(:user, email: 'dup@example.com')

      post '/signup', params: { user: { email: 'dup@example.com', password: valid_password, password_confirmation: valid_password } }.to_json, headers: headers

  expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body['errors'].join(' ')).to match(/has already been taken|already been taken/i)
    end
  end
end
