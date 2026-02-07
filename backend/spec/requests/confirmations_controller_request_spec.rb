require 'rails_helper'

RSpec.describe 'Confirmations Controller', type: :request do
  before do
    clear_mail_deliveries
  end

  it 'routes confirmation link from email to the confirmations controller and confirms the user' do
    post '/signup', params: { user: { email: 'controller_confirm@example.com', password: valid_password, password_confirmation: valid_password } }.to_json, headers: json_headers
    expect(response).to have_http_status(:ok)

    mail = last_delivery
    expect(mail).to be_present

    # Extract path from the email body
    path = extract_confirmation_path_from_mail(mail)
    expect(path).to be_present

    # Perform controller-level GET to the confirmation URL
    get path, headers: json_headers
    expect(response).to have_http_status(:ok)

    body = json_response
    expect(body['status']).to be_present
    expect(body['status']['message']).to match(/email confirmed/i)

    user = User.find_by(email: 'controller_confirm@example.com')
    expect(user.confirmed_at).to be_present

    # After confirmation, login should succeed and return a token
    post '/login', params: { user: { email: user.email, password: valid_password } }.to_json, headers: json_headers
    expect(response).to have_http_status(:ok)
    login_body = json_response
    expect(login_body['token']).to be_present
  end
end
