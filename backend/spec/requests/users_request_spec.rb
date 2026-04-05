require 'rails_helper'

RSpec.describe 'Users API', type: :request do
  describe 'GET /users' do
    it 'returns users for admin' do
      admin = create(:user, :admin)
      create_list(:user, 2)
      get '/users', headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body['message']).to match(/Users found|Success/i)
    end

    it 'includes system_user and person_id fields in the response' do
      admin = create(:user, :admin)
      get '/users', headers: auth_headers_for(admin)

      user_data = json_response['users'].first
      expect(user_data).to have_key('system_user')
      expect(user_data).to have_key('person_id')
    end

    it 'includes system users in the list' do
      admin = create(:user, :admin)
      system = create(:user, :system_user)
      get '/users', headers: auth_headers_for(admin)

      ids = json_response['users'].map { |u| u['id'] }
      expect(ids).to include(system.id)
    end

    it 'returns 401 when unauthenticated' do
      get '/users', headers: json_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 403 when non-admin accesses' do
      user = create(:user)
      get '/users', headers: auth_headers_for(user)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /users/:id' do
    it 'shows a user when authorized' do
      admin = create(:user, :admin)
      user = create(:user)
      get "/users/#{user.id}", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body['message']).to match(/User found|Success/i)
    end

    it 'returns 404 when user does not exist' do
      admin = create(:user, :admin)
      get '/users/99999', headers: auth_headers_for(admin)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 when unauthenticated' do
      user = create(:user)
      get "/users/#{user.id}", headers: json_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 403 when non-admin accesses' do
      user = create(:user)
      other_user = create(:user)
      get "/users/#{other_user.id}", headers: auth_headers_for(user)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PATCH /users/:id' do
    it 'updates a user when authorized' do
      admin = create(:user, :admin)
      user = create(:user)
      role = create(:role)
      patch "/users/#{user.id}", params: { user: { role_ids: [role.id] } }.to_json, headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(user.reload.roles.map(&:id)).to include(role.id)
    end

    it 'returns 404 when user does not exist' do
      admin = create(:user, :admin)
      patch '/users/99999', params: { user: { role_ids: [] } }.to_json, headers: auth_headers_for(admin)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 when unauthenticated' do
      user = create(:user)
      patch "/users/#{user.id}", params: { user: { role_ids: [] } }.to_json, headers: json_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 403 when non-admin tries to update' do
      user = create(:user)
      other_user = create(:user)
      patch "/users/#{other_user.id}", params: { user: { role_ids: [] } }.to_json, headers: auth_headers_for(user)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /users/:id' do
    it 'discards a user when authorized' do
      admin = create(:user, :admin)
      user = create(:user)
      delete "/users/#{user.id}", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(user.reload.discarded?).to be true
    end

    it 'returns 404 when user does not exist' do
      admin = create(:user, :admin)
      delete '/users/99999', headers: auth_headers_for(admin)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 when unauthenticated' do
      user = create(:user)
      delete "/users/#{user.id}", headers: json_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 403 when non-admin tries to delete' do
      user = create(:user)
      other_user = create(:user)
      delete "/users/#{other_user.id}", headers: auth_headers_for(user)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
