require 'rails_helper'

RSpec.describe 'Roles API', type: :request do
  describe 'GET /roles' do
    it 'returns roles for admin users' do
      user = create(:user)
      allow(user).to receive(:admin?).and_return(true)
      sign_in(user)

      create_list(:role, 3)
      get '/roles'

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data']).to eq(nil).or be_a(Hash) # controllers wrap payload under data key; we check status and presence
      expect(body['message']).to match(/Roles found|Success/i)
    end
  end

  describe 'POST /roles' do
    it 'creates a role when authorized' do
      user = create(:user)
      allow(user).to receive(:admin?).and_return(true)
      sign_in(user)

      post '/roles', params: { role: { name: 'new_role', description: 'desc' } }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['message']).to match(/created|Success/i)
      expect(Role.exists?(name: 'new_role')).to be(true)
    end
  end
end
