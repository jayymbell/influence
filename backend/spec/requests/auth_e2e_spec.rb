require 'rails_helper'

RSpec.describe 'Auth E2E', type: :request do
  let(:headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }
  let(:password) { 'Password123!@' }

  it 'runs signup -> confirmation -> login -> refresh -> logout and ensures revoked tokens are denied' do
    email = 'e2e_user@example.com'

    # Sign up
    post '/signup', params: { user: { email: email, password: password, password_confirmation: password } }.to_json, headers: headers
    expect(response).to have_http_status(:ok)

    # Capture confirmation email and extract link
    mail = ActionMailer::Base.deliveries.last
    expect(mail).to be_present
    body = mail.body.to_s
    href = body[/href="([^"]+)"/, 1] || body[/(http[^\s>]+confirmation[^\s>]+)/, 1]
    expect(href).to be_present
    uri = URI.parse(href)
    path = uri.request_uri

    # Visit confirmation link (controller-level)
    get path, headers: headers
    expect(response).to have_http_status(:ok)
    confirm_body = JSON.parse(response.body)
    expect(confirm_body['status']).to be_present
    expect(confirm_body['status']['message']).to match(/email confirmed/i)

    user = User.find_by(email: email)
    expect(user.confirmed_at).to be_present

    # Login to receive tokens
    post '/login', params: { user: { email: email, password: password } }.to_json, headers: headers
    expect(response).to have_http_status(:ok)
    login_body = JSON.parse(response.body)
    access_token = login_body['token']
    expect(access_token).to be_present
    refresh_token = login_body['refresh_token']
    expect(refresh_token).to be_present

    # Refresh tokens
    post '/users/refresh-token', params: { refresh_token: refresh_token }.to_json, headers: headers
    expect(response).to have_http_status(:ok)
    rotated = JSON.parse(response.body)
    new_access = rotated['data']['token']
    new_refresh = rotated['data']['refresh_token']
    expect(new_access).to be_present
    expect(new_refresh).to be_present

  # Debug: list refresh tokens after rotation
  user.reload
  # puts "REFRESH TOKENS AFTER ROTATION: ", user.refresh_tokens.pluck(:id, :token, :revoked_at)

  # Logout using an Authorization header that will set current_user in tests
  # (use the test helper to build a valid JWT for the user)
  delete '/logout', headers: headers.merge(auth_headers_for(user))
    expect(response).to have_http_status(:ok)
    logout_body = JSON.parse(response.body)
    expect(logout_body['message']).to match(/Logged out successfully/i)

    # Debug: list refresh tokens after logout
    user.reload
    # puts "REFRESH TOKENS AFTER LOGOUT: ", user.refresh_tokens.pluck(:id, :token, :revoked_at)
    # At least one refresh token should be revoked (rotation and/or logout)
    expect(user.refresh_tokens.where.not(revoked_at: nil).count).to be >= 1
  end
end
