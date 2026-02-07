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

  describe 'GET /roles/:id' do
    it 'returns a role when authorized' do
      user = create(:user, :admin)
      role = create(:role)
      get "/roles/#{role.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body['message']).to match(/Role found|Success/i)
      expect(body['role']).to be_present
    end

    it 'returns 404 when role does not exist' do
      user = create(:user, :admin)
      get '/roles/99999', headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
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

  describe 'PATCH /roles/:id' do
    it 'updates a role when authorized' do
      user = create(:user, :admin)
      role = create(:role, name: 'old_name', description: 'old_desc')
      patch "/roles/#{role.id}", params: { role: { name: 'updated_name', description: 'updated_desc' } }.to_json, headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body['message']).to match(/updated|Success/i)
      role.reload
      expect(role.name).to eq('updated_name')
      expect(role.description).to eq('updated_desc')
    end

    it 'returns 422 when update fails validation' do
      user = create(:user, :admin)
      role = create(:role, name: 'unique_role')
      create(:role, name: 'taken_name')

      patch "/roles/#{role.id}", params: { role: { name: 'taken_name' } }.to_json, headers: auth_headers_for(user)

      expect(response).to have_http_status(:unprocessable_content)
      body = json_response
      expect(body['errors']).to be_present
    end
  end

  describe 'DELETE /roles/:id' do
    it 'deletes a role when authorized' do
      user = create(:user, :admin)
      role = create(:role)

      delete "/roles/#{role.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body['message']).to match(/deleted|Success/i)
      expect(Role.find_by(id: role.id)).to be_nil
    end

    it 'prevents deleting the admin role' do
      user = create(:user, :admin)
      admin_role = Role.find_or_create_by!(name: 'admin') { |r| r.description = 'Administrator' }

      delete "/roles/#{admin_role.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
      expect(Role.find_by(id: admin_role.id)).to be_present
    end
  end
end
