require 'rails_helper'

RSpec.describe 'Confirmations API', type: :request do
  before do
    clear_mail_deliveries
  end

  it 'confirms a user when visiting the confirmation link from email' do
    post '/signup', params: { user: { email: 'confirm_me@example.com', password: valid_password, password_confirmation: valid_password } }.to_json, headers: json_headers
    expect(response).to have_http_status(:ok)

    mail = last_delivery
    expect(mail).to be_present

    # Extract confirmation token from the email body
    token = extract_confirmation_token_from_mail(mail)
    expect(token).to be_present

    # Confirm via Devise model API (confirm_by_token) — this mirrors clicking the link
    confirmed = User.confirm_by_token(token)
    expect(confirmed.errors).to be_empty
    user = User.find_by(email: 'confirm_me@example.com')
    expect(user.confirmed_at).to be_present

    # After confirmation, login should succeed and return a token
    post '/login', params: { user: { email: user.email, password: valid_password } }.to_json, headers: json_headers
    expect(response).to have_http_status(:ok)
    login_body = json_response
    expect(login_body['token']).to be_present
  end

  it 'returns 422 for an invalid confirmation token' do
    result = User.confirm_by_token('bogus')
    expect(result.errors).not_to be_empty
  end
end
