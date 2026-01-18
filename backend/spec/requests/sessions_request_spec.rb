require 'rails_helper'

RSpec.describe 'Sessions API', type: :request do
  describe 'DELETE /logout' do
    context 'with valid Authorization header' do
      it 'revokes refresh tokens and returns success' do
        user = create(:user)
        # create a refresh token for the user
        refresh_token = user.refresh_tokens.create!

        # make request with a real JWT
        delete '/logout', headers: auth_headers_for(user)

        expect(response).to have_http_status(:ok)
        body = json_response
        expect(body['message']).to match(/Logged out successfully/i)

        expect(refresh_token.reload.revoked_at).to be_present
        expect(refresh_token.reload.revocation_reason).to eq('logout')
      end
    end

    context 'without Authorization header' do
      it 'returns token not found message' do
        delete '/logout', headers: json_headers

        expect(response).to have_http_status(:unauthorized)
        body = json_response
        expect(body['message']).to match(/Token not found/i)
        expect(body['status']).to eq(401)
      end
    end
  end
end
