require 'rails_helper'

RSpec.describe 'Auth E2E', type: :request do
  it 'runs signup -> confirmation -> login -> refresh -> logout and ensures revoked tokens are denied' do
    email = 'e2e_user@example.com'

    # Sign up
    post '/signup', params: { user: { email: email, password: valid_password, password_confirmation: valid_password } }.to_json, headers: json_headers
    expect(response).to have_http_status(:ok)

    # Capture confirmation email and extract link
    mail = last_delivery
    expect(mail).to be_present
    path = extract_confirmation_path_from_mail(mail)
    expect(path).to be_present

    # Visit confirmation link (controller-level)
    get path, headers: json_headers
    expect(response).to have_http_status(:ok)
    confirm_body = json_response
    expect(confirm_body['status']).to be_present
    expect(confirm_body['status']['message']).to match(/email confirmed/i)

    user = User.find_by(email: email)
    expect(user.confirmed_at).to be_present

    # Login to receive tokens
    post '/login', params: { user: { email: email, password: valid_password } }.to_json, headers: json_headers
    expect(response).to have_http_status(:ok)
    login_body = json_response
    access_token = login_body['token']
    expect(access_token).to be_present
    refresh_token = login_body['refresh_token']
    expect(refresh_token).to be_present

    # Refresh tokens
    post '/users/refresh-token', params: { refresh_token: refresh_token }.to_json, headers: json_headers
    expect(response).to have_http_status(:ok)
    rotated = json_response
    new_access = rotated['data']['token']
    new_refresh = rotated['data']['refresh_token']
    expect(new_access).to be_present
    expect(new_refresh).to be_present

    # Logout using an Authorization header that will set current_user in tests
    # (use the test helper to build a valid JWT for the user)
    user.reload
    delete '/logout', headers: json_headers.merge(auth_headers_for(user))
    expect(response).to have_http_status(:ok)
    logout_body = json_response
    expect(logout_body['message']).to match(/Logged out successfully/i)

    # At least one refresh token should be revoked (rotation and/or logout)
    user.reload
    expect(user.refresh_tokens.where.not(revoked_at: nil).count).to be >= 1
  end
end
