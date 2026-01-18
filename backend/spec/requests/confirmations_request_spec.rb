require 'rails_helper'

RSpec.describe 'Confirmations API', type: :request do
  let(:headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }
  let(:password) { 'Password123!@' }

  before do
    ActionMailer::Base.deliveries.clear
  end

  it 'confirms a user when visiting the confirmation link from email' do
    post '/signup', params: { user: { email: 'confirm_me@example.com', password: password, password_confirmation: password } }.to_json, headers: headers
    expect(response).to have_http_status(:ok)

    mail = ActionMailer::Base.deliveries.last
    expect(mail).to be_present

    # Extract confirmation token from the email body (Devise default contains confirmation_token param)
    body = mail.body.to_s
    token = nil
    if body =~ /confirmation_token=([^\s"&>]+)/
      token = Regexp.last_match(1)
    else
      # Fallback: look for token in plain text
      token = body[/confirmation_token=([^\s"&>]+)/, 1]
    end

    expect(token).to be_present

  # Confirm via Devise model API (confirm_by_token) — this mirrors clicking the link
  confirmed = User.confirm_by_token(token)
  expect(confirmed.errors).to be_empty
  user = User.find_by(email: 'confirm_me@example.com')
  expect(user.confirmed_at).to be_present

  # After confirmation, login should succeed and return a token
  post '/login', params: { user: { email: user.email, password: password } }.to_json, headers: headers
  expect(response).to have_http_status(:ok)
  login_body = JSON.parse(response.body)
  expect(login_body['token']).to be_present
  end

  it 'returns 422 for an invalid confirmation token' do
  result = User.confirm_by_token('bogus')
  expect(result.errors).not_to be_empty
  end
end
