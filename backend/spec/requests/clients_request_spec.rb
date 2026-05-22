# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Clients API', type: :request do
  describe 'GET /clients' do
    it 'returns active clients for admin' do
      user = create(:user, :admin)
      create_list(:client, 3)
      get '/clients', headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to match(/Clients found/i)
      expect(json_response['clients'].length).to eq(3)
    end

    it 'returns active clients for staff' do
      user = create(:user, :with_role, role_name: 'staff')
      create_list(:client, 2)
      get '/clients', headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['clients'].length).to eq(2)
    end

    it 'returns 403 for unauthorized users' do
      user = create(:user)
      get '/clients', headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 401 for unauthenticated requests' do
      get '/clients'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'excludes discarded clients by default' do
      user = create(:user, :admin)
      create(:client)
      create(:client, :discarded)
      get '/clients', headers: auth_headers_for(user)

      expect(json_response['clients'].length).to eq(1)
    end

    it 'returns discarded clients when discarded=true' do
      user = create(:user, :admin)
      create(:client)
      create(:client, :discarded)
      get '/clients', params: { discarded: 'true' }, headers: auth_headers_for(user)

      expect(json_response['clients'].length).to eq(1)
      expect(json_response['clients'].first['status']).to eq('inactive')
    end

    it 'filters by query (legal name and display name)' do
      user = create(:user, :admin)
      create(:client, legal_name: 'Acme Corporation', display_name: 'Acme')
      create(:client, legal_name: 'Beta LLC', display_name: 'Beta')
      get '/clients', params: { query: 'acme' }, headers: auth_headers_for(user)

      expect(json_response['clients'].length).to eq(1)
      expect(json_response['clients'].first['legal_name']).to eq('Acme Corporation')
    end

    it 'paginates results' do
      user = create(:user, :admin)
      create_list(:client, 5)
      get '/clients', params: { page: 1, per_page: 2 }, headers: auth_headers_for(user)

      expect(json_response['clients'].length).to eq(2)
    end
  end

  describe 'GET /clients/:id' do
    it 'returns client detail for admin' do
      user   = create(:user, :admin)
      client = create(:client)
      get "/clients/#{client.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['client']['id']).to eq(client.id)
      expect(json_response['client']['status']).to eq('active')
    end

    it 'returns 403 for unauthorized users' do
      user   = create(:user)
      client = create(:client)
      get "/clients/#{client.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 404 when client does not exist' do
      user = create(:user, :admin)
      get '/clients/99999', headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /clients' do
    let(:admin) { create(:user, :admin) }
    let(:valid_params) do
      { client: { legal_name: 'Acme Corporation', display_name: 'Acme' } }.to_json
    end

    it 'creates a client for admin' do
      post '/clients', params: valid_params, headers: auth_headers_for(admin)

      expect(response).to have_http_status(:created)
      expect(json_response['client']['legal_name']).to eq('Acme Corporation')
      expect(json_response['client']['status']).to eq('active')
    end

    it 'sets created_by and updated_by to current user' do
      post '/clients', params: valid_params, headers: auth_headers_for(admin)

      client = Client.last
      expect(client.created_by).to eq(admin)
      expect(client.updated_by).to eq(admin)
    end

    it 'returns 422 when legal_name is missing' do
      post '/clients',
           params: { client: { display_name: 'Acme' } }.to_json,
           headers: auth_headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors']).to be_present
    end

    it 'returns 422 on duplicate legal name (case-insensitive, including inactive clients)' do
      create(:client, legal_name: 'Acme Corporation')
      post '/clients',
           params: { client: { legal_name: 'acme corporation', display_name: 'Acme 2' } }.to_json,
           headers: auth_headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors']).to be_present
    end

    it 'returns 403 for unauthorized users' do
      user = create(:user)
      post '/clients', params: valid_params, headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PATCH /clients/:id' do
    let(:admin)  { create(:user, :admin) }
    let(:client) { create(:client) }

    it 'updates a client for admin' do
      patch "/clients/#{client.id}",
            params: { client: { display_name: 'Updated Name' } }.to_json,
            headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['client']['display_name']).to eq('Updated Name')
    end

    it 'sets updated_by' do
      patch "/clients/#{client.id}",
            params: { client: { display_name: 'X' } }.to_json,
            headers: auth_headers_for(admin)

      expect(client.reload.updated_by).to eq(admin)
    end

    it 'returns 403 for unauthorized users' do
      user = create(:user)
      patch "/clients/#{client.id}",
            params: { client: { display_name: 'X' } }.to_json,
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /clients/:id (soft deactivate)' do
    let(:admin)  { create(:user, :admin) }
    let(:client) { create(:client) }

    it 'deactivates a client' do
      delete "/clients/#{client.id}", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to match(/deactivated/i)
      expect(client.reload.discarded?).to be true
      expect(client.reload.deactivated_at).to be_present
      expect(client.reload.deactivated_by).to eq(admin)
    end

    it 'excludes deactivated client from default list' do
      delete "/clients/#{client.id}", headers: auth_headers_for(admin)

      get '/clients', headers: auth_headers_for(admin)
      ids = json_response['clients'].map { |c| c['id'] }
      expect(ids).not_to include(client.id)
    end

    it 'returns 403 for unauthorized users' do
      user = create(:user)
      delete "/clients/#{client.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /clients/:id/reactivate' do
    let(:admin)  { create(:user, :admin) }
    let(:client) { create(:client, :discarded) }

    it 'reactivates an inactive client' do
      post "/clients/#{client.id}/reactivate", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['client']['status']).to eq('active')
      expect(client.reload.discarded?).to be false
      expect(client.reload.deactivated_at).to be_nil
    end

    it 'returns 403 for unauthorized users' do
      user = create(:user)
      post "/clients/#{client.id}/reactivate", headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
