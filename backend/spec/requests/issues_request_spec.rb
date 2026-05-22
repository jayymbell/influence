# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Issues API', type: :request do
  # ---------------------------------------------------------------------------
  # GET /issues
  # ---------------------------------------------------------------------------
  describe 'GET /issues' do
    it 'returns issues for admin' do
      user = create(:user, :admin)
      create_list(:issue, 3)
      get '/issues', headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to match(/Issues found/i)
      expect(json_response['issues'].length).to eq(3)
    end

    it 'returns issues for staff' do
      user = create(:user, :with_role, role_name: 'staff')
      create_list(:issue, 2)
      get '/issues', headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['issues'].length).to eq(2)
    end

    it 'returns only the manager\'s client issues' do
      user    = create(:user, :with_role, role_name: 'manager')
      client  = create(:client)
      create(:client_staff, client: client, user: user)
      issue = create(:issue)
      create(:client_issue, issue: issue, client: client)
      create(:issue) # no client_issue for this manager — not visible

      get '/issues', headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['issues'].length).to eq(1)
    end

    it 'returns 403 for regular users' do
      user = create(:user)
      get '/issues', headers: auth_headers_for(user)
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 401 for unauthenticated requests' do
      get '/issues'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'filters by status' do
      user = create(:user, :admin)
      create(:issue, status: :active)
      create(:issue, status: :inactive)
      create(:issue, status: :closed)

      get '/issues', params: { status: 'active' }, headers: auth_headers_for(user)

      expect(json_response['issues'].all? { |i| i['status'] == 'active' }).to be true
    end

    it 'filters by client_id' do
      user   = create(:user, :admin)
      client = create(:client)
      issue  = create(:issue)
      create(:client_issue, issue: issue, client: client)
      create(:issue) # unrelated

      get '/issues', params: { client_id: client.id }, headers: auth_headers_for(user)

      expect(json_response['issues'].length).to eq(1)
    end

    it 'filters by query on title' do
      user = create(:user, :admin)
      create(:issue, title: 'Budget Reform')
      create(:issue, title: 'Transportation Bill')

      get '/issues', params: { query: 'budget' }, headers: auth_headers_for(user)

      expect(json_response['issues'].length).to eq(1)
      expect(json_response['issues'].first['title']).to eq('Budget Reform')
    end
  end

  # ---------------------------------------------------------------------------
  # GET /issues/:id
  # ---------------------------------------------------------------------------
  describe 'GET /issues/:id' do
    it 'returns issue for admin' do
      user  = create(:user, :admin)
      issue = create(:issue)

      get "/issues/#{issue.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['issue']['title']).to eq(issue.title)
    end

    it 'returns 403 for regular user' do
      user  = create(:user)
      issue = create(:issue)

      get "/issues/#{issue.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /issues
  # ---------------------------------------------------------------------------
  describe 'POST /issues' do
    let(:client) { create(:client) }

    it 'creates an issue for admin' do
      user = create(:user, :admin)
      post '/issues',
           params: { issue: { title: 'New Issue', client_id: client.id } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      expect(json_response['issue']['title']).to eq('New Issue')
      expect(json_response['issue']['status']).to eq('active')
    end

    it 'creates an issue for staff' do
      user = create(:user, :with_role, role_name: 'staff')
      post '/issues',
           params: { issue: { title: 'Staff Issue', client_id: client.id } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
    end

    it 'creates an issue with tags' do
      user = create(:user, :admin)
      post '/issues',
           params: { issue: { title: 'Tagged Issue', client_id: client.id, tags: %w[healthcare energy] } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      expect(json_response['issue']['tags']).to eq(%w[healthcare energy])
    end

    it 'returns validation errors for missing title' do
      user = create(:user, :admin)
      post '/issues',
           params: { issue: { title: '', client_id: client.id } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to be_present
    end

    it 'returns 403 for regular user' do
      user = create(:user)
      post '/issues',
           params: { issue: { title: 'Nope', client_id: client.id } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /issues/:id
  # ---------------------------------------------------------------------------
  describe 'PATCH /issues/:id' do
    it 'updates an issue for admin' do
      user  = create(:user, :admin)
      issue = create(:issue)

      patch "/issues/#{issue.id}",
            params: { issue: { title: 'Updated Title' } }.to_json,
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['issue']['title']).to eq('Updated Title')
    end

    it 'returns 403 for regular user' do
      user  = create(:user)
      issue = create(:issue)

      patch "/issues/#{issue.id}",
            params: { issue: { title: 'Nope' } }.to_json,
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /issues/:id/close
  # ---------------------------------------------------------------------------
  describe 'POST /issues/:id/close' do
    it 'closes an issue and stamps closed_at' do
      user  = create(:user, :admin)
      issue = create(:issue)

      post "/issues/#{issue.id}/close", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['issue']['status']).to eq('closed')
      expect(json_response['issue']['closed_at']).to be_present
    end

    it 'returns 403 for regular user' do
      user  = create(:user)
      issue = create(:issue)

      post "/issues/#{issue.id}/close", headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /issues/:id/deactivate
  # ---------------------------------------------------------------------------
  describe 'POST /issues/:id/deactivate' do
    it 'sets issue to inactive' do
      user  = create(:user, :admin)
      issue = create(:issue)

      post "/issues/#{issue.id}/deactivate", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['issue']['status']).to eq('inactive')
    end
  end

  # ---------------------------------------------------------------------------
  # POST /issues/:id/reactivate
  # ---------------------------------------------------------------------------
  describe 'POST /issues/:id/reactivate' do
    it 'reactivates a closed or inactive issue' do
      user  = create(:user, :admin)
      issue = create(:issue, :closed)

      post "/issues/#{issue.id}/reactivate", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['issue']['status']).to eq('active')
      expect(json_response['issue']['closed_at']).to be_nil
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /issues/:id
  # ---------------------------------------------------------------------------
  describe 'DELETE /issues/:id' do
    it 'sets issue to inactive (soft)' do
      user  = create(:user, :admin)
      issue = create(:issue)

      delete "/issues/#{issue.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(issue.reload.status).to eq('inactive')
    end
  end

  # ---------------------------------------------------------------------------
  # GET /issues/:issue_id/clients
  # ---------------------------------------------------------------------------
  describe 'GET /issues/:issue_id/clients' do
    it 'returns shared clients for admin' do
      user   = create(:user, :admin)
      issue  = create(:issue)
      client = create(:client)
      create(:client_issue, issue: issue, client: client)

      get "/issues/#{issue.id}/clients", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['clients'].length).to eq(1)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /issues/:issue_id/clients — share
  # ---------------------------------------------------------------------------
  describe 'POST /issues/:issue_id/clients' do
    let(:admin)  { create(:user, :admin) }
    let(:staff)  { create(:user, :with_role, role_name: 'staff') }
    let(:issue)  { create(:issue) }
    let(:client) { create(:client) }

    it 'allows admin to share issue with another client' do
      post "/issues/#{issue.id}/clients",
           params: { client_id: client.id }.to_json,
           headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['clients'].any? { |c| c['id'] == client.id }).to be true
    end

    it 'returns 403 for staff (cannot share)' do
      post "/issues/#{issue.id}/clients",
           params: { client_id: client.id }.to_json,
           headers: auth_headers_for(staff)

      expect(response).to have_http_status(:forbidden)
    end

    it 'prevents duplicate sharing' do
      create(:client_issue, issue: issue, client: client)

      post "/issues/#{issue.id}/clients",
           params: { client_id: client.id }.to_json,
           headers: auth_headers_for(admin)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /issues/:issue_id/clients/:id — unshare
  # ---------------------------------------------------------------------------
  describe 'DELETE /issues/:issue_id/clients/:id' do
    it 'allows admin to unshare issue from a client' do
      user   = create(:user, :admin)
      issue  = create(:issue)
      client = create(:client)
      create(:client_issue, issue: issue, client: client)

      delete "/issues/#{issue.id}/clients/#{client.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(issue.client_issues.where(client: client).count).to eq(0)
    end

    it 'returns 403 for staff' do
      user   = create(:user, :with_role, role_name: 'staff')
      issue  = create(:issue)
      client = create(:client)
      create(:client_issue, issue: issue, client: client)

      delete "/issues/#{issue.id}/clients/#{client.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /issues/:issue_id/people
  # ---------------------------------------------------------------------------
  describe 'POST /issues/:issue_id/people' do
    it 'adds a person to an issue' do
      user   = create(:user, :admin)
      issue  = create(:issue)
      person = create(:person)

      post "/issues/#{issue.id}/people",
           params: { person_id: person.id }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['people'].any? { |p| p['id'] == person.id }).to be true
    end

    it 'prevents duplicate person assignment' do
      user   = create(:user, :admin)
      issue  = create(:issue)
      person = create(:person)
      create(:issue_person, issue: issue, person: person)

      post "/issues/#{issue.id}/people",
           params: { person_id: person.id }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /issues/:issue_id/people/:id — remove person
  # ---------------------------------------------------------------------------
  describe 'DELETE /issues/:issue_id/people/:id' do
    it 'removes a person from an issue' do
      user   = create(:user, :admin)
      issue  = create(:issue)
      person = create(:person)
      create(:issue_person, issue: issue, person: person)

      delete "/issues/#{issue.id}/people/#{person.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(issue.issue_people.where(person: person).count).to eq(0)
    end
  end
end
