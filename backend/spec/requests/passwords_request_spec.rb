require 'rails_helper'

RSpec.describe 'Passwords API', type: :request do
  describe 'POST /password' do
    it 'returns 200 and does not reveal account existence (paranoid response)' do
      user = create(:user)

      post '/password', params: { user: { email: user.email } }.to_json, headers: json_headers

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body['status']).to be_present
      expect(body['status']['code']).to eq(200)
    end
  end

  describe 'PUT /password' do
    it 'resets password with a valid token' do
      user = create(:user)
      # Trigger reset email
      post '/password', params: { user: { email: user.email } }.to_json, headers: json_headers
      mail = last_delivery
      expect(mail).to be_present
      body = mail.body.to_s
      token = body[/reset_password_token=([^\s"&>]+)/, 1]
      expect(token).to be_present

      new_pw = valid_password
      put '/password', params: { user: { reset_password_token: token, password: new_pw, password_confirmation: new_pw } }.to_json, headers: json_headers

      expect(response).to have_http_status(:ok)
      resp = json_response
      expect(resp['status']).to be_present
      # success path uses Devise i18n key
      expect(resp['status']['message']).to match(/updated|password/i)
    end

    it 'returns 422 for invalid reset token' do
      user = create(:user)
      put '/password', params: { user: { reset_password_token: 'badtoken', password: 'Abcd1234!@', password_confirmation: 'Abcd1234!@' } }.to_json, headers: json_headers

      expect(response).to have_http_status(:unprocessable_content)
      body = json_response
      expect(body['errors']).to be_present
    end
  end
end
