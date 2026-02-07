require 'rails_helper'

RSpec.describe 'Registrations Update API', type: :request do
  describe 'PATCH /signup' do
    it 'updates password when current_password is provided' do
      user = create(:user, password: valid_password, password_confirmation: valid_password)

      new_pw = 'Newpassword123!'
      patch '/signup', params: { user: { current_password: valid_password, password: new_pw, password_confirmation: new_pw } }.to_json, headers: auth_headers_for(user).merge(json_headers)

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body['message']).to match(/updated|Success|confirmed/i)
      # Verify the password changed by attempting to sign in (simulate via Devise)
      user.reload
      expect(user.valid_password?(new_pw)).to be true
    end

    it 'returns 422 when current_password is incorrect' do
      user = create(:user, password: valid_password, password_confirmation: valid_password)

      patch '/signup', params: { user: { current_password: 'wrong', password: 'Xyz12345!@', password_confirmation: 'Xyz12345!@' } }.to_json, headers: auth_headers_for(user).merge(json_headers)

      expect(response).to have_http_status(:unprocessable_content)
      body = json_response
      expect(body['errors']).to be_present
    end
  end
end
