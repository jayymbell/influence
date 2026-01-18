require 'rails_helper'

RSpec.describe 'Roles API', type: :request do
  describe 'GET /roles' do
    it 'returns roles for admin users' do
      user = create(:user, :admin)
      create_list(:role, 3)
      get '/roles', headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body['message']).to match(/Roles found|Success/i)
    end
  end

  describe 'POST /roles' do
    it 'creates a role when authorized' do
      user = create(:user, :admin)
      post '/roles', params: { role: { name: 'new_role', description: 'desc' } }.to_json, headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body['message']).to match(/created|Success/i)
      expect(Role.exists?(name: 'new_role')).to be(true)
    end
  end
end
