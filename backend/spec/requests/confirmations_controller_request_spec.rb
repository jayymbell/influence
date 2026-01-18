require 'rails_helper'

RSpec.describe 'Confirmations Controller', type: :request do
  let(:headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }
  let(:password) { 'Password123!@' }

  before do
    ActionMailer::Base.deliveries.clear
  end

  it 'routes confirmation link from email to the confirmations controller and confirms the user' do
    post '/signup', params: { user: { email: 'controller_confirm@example.com', password: password, password_confirmation: password } }.to_json, headers: headers
    expect(response).to have_http_status(:ok)

    mail = ActionMailer::Base.deliveries.last
    expect(mail).to be_present

    # Extract href from the email body
    body = mail.body.to_s
    href = body[/href="([^"]+)"/, 1] || body[/(http[^\s>]+confirmation[^\s>]+)/, 1]
    expect(href).to be_present

    # Convert to path (e.g. /confirmation?confirmation_token=...)
    uri = URI.parse(href)
    path = uri.request_uri

    # Perform controller-level GET to the confirmation URL
    get path, headers: headers
    expect(response).to have_http_status(:ok)

    body = JSON.parse(response.body)
    expect(body['status']).to be_present
    expect(body['status']['message']).to match(/email confirmed/i)

    user = User.find_by(email: 'controller_confirm@example.com')
    expect(user.confirmed_at).to be_present

    # After confirmation, login should succeed and return a token
    post '/login', params: { user: { email: user.email, password: password } }.to_json, headers: headers
    expect(response).to have_http_status(:ok)
    login_body = JSON.parse(response.body)
    expect(login_body['token']).to be_present
  end
end
