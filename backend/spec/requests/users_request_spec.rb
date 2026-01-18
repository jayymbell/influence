require 'rails_helper'

RSpec.describe 'Users API', type: :request do
  describe 'GET /users' do
    it 'returns users for admin' do
  admin = create(:user)
  Role.find_or_create_by!(name: 'admin') { |r| r.description = 'Administrator' }
  admin.roles << Role.find_by(name: 'admin')

  create_list(:user, 2)
  get '/users', headers: auth_headers_for(admin)

  expect(response).to have_http_status(:ok)
  body = JSON.parse(response.body)
  expect(body['message']).to match(/Users found|Success/i)
    end
  end

  describe 'GET /users/:id' do
    it 'shows a user when authorized' do
  admin = create(:user)
  Role.find_or_create_by!(name: 'admin') { |r| r.description = 'Administrator' }
  admin.roles << Role.find_by(name: 'admin')

  user = create(:user)
  get "/users/#{user.id}", headers: auth_headers_for(admin)

  expect(response).to have_http_status(:ok)
  body = JSON.parse(response.body)
  expect(body['message']).to match(/User found|Success/i)
    end
  end

  describe 'PATCH /users/:id' do
    it 'updates a user when authorized' do
  admin = create(:user)
  Role.find_or_create_by!(name: 'admin') { |r| r.description = 'Administrator' }
  admin.roles << Role.find_by(name: 'admin')

  user = create(:user)
  role = create(:role)
  patch "/users/#{user.id}", params: { user: { role_ids: [role.id] } }.to_json, headers: auth_headers_for(admin)

  expect(response).to have_http_status(:ok)
  expect(user.reload.roles.map(&:id)).to include(role.id)
    end
  end

  describe 'DELETE /users/:id' do
    it 'discards a user when authorized' do
  admin = create(:user)
  Role.find_or_create_by!(name: 'admin') { |r| r.description = 'Administrator' }
  admin.roles << Role.find_by(name: 'admin')

  user = create(:user)
  delete "/users/#{user.id}", headers: auth_headers_for(admin)

  expect(response).to have_http_status(:ok)
  expect(user.reload.discarded?).to be true
    end
  end
end
