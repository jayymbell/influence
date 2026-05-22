# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bills API', type: :request do
  # ---------------------------------------------------------------------------
  # GET /bills
  # ---------------------------------------------------------------------------
  describe 'GET /bills' do
    it 'returns bills for admin' do
      user = create(:user, :admin)
      create_list(:bill, 3)
      get '/bills', headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to match(/Bills found/i)
      expect(json_response['bills'].length).to eq(3)
    end

    it 'returns bills for staff' do
      user = create(:user, :with_role, role_name: 'staff')
      create_list(:bill, 2)
      get '/bills', headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['bills'].length).to eq(2)
    end

    it 'returns only the manager\'s client bills' do
      user   = create(:user, :with_role, role_name: 'manager')
      client = create(:client)
      create(:client_staff, client: client, user: user)
      bill = create(:bill)
      create(:bill_client, bill: bill, client: client)
      create(:bill) # not linked to manager's client

      get '/bills', headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['bills'].length).to eq(1)
    end

    it 'returns 403 for regular users' do
      user = create(:user)
      get '/bills', headers: auth_headers_for(user)
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 401 for unauthenticated requests' do
      get '/bills'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'filters by status' do
      user = create(:user, :admin)
      create(:bill, status: :introduced)
      create(:bill, status: :signed)

      get '/bills', params: { status: 'introduced' }, headers: auth_headers_for(user)

      expect(json_response['bills'].all? { |b| b['status'] == 'introduced' }).to be true
    end

    it 'filters by chamber' do
      user = create(:user, :admin)
      create(:bill, :house)
      create(:bill, :senate)

      get '/bills', params: { chamber: 'house' }, headers: auth_headers_for(user)

      expect(json_response['bills'].all? { |b| b['chamber'] == 'house' }).to be true
      expect(json_response['bills'].length).to eq(1)
    end

    it 'filters by query on title' do
      user = create(:user, :admin)
      create(:bill, title: 'Education Funding Act')
      create(:bill, title: 'Transportation Bill')

      get '/bills', params: { query: 'education' }, headers: auth_headers_for(user)

      expect(json_response['bills'].length).to eq(1)
      expect(json_response['bills'].first['title']).to eq('Education Funding Act')
    end

    it 'filters by client_id' do
      user   = create(:user, :admin)
      client = create(:client)
      bill   = create(:bill)
      create(:bill_client, bill: bill, client: client)
      create(:bill) # unrelated

      get '/bills', params: { client_id: client.id }, headers: auth_headers_for(user)

      expect(json_response['bills'].length).to eq(1)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /bills/:id
  # ---------------------------------------------------------------------------
  describe 'GET /bills/:id' do
    it 'returns bill for admin' do
      user = create(:user, :admin)
      bill = create(:bill)

      get "/bills/#{bill.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['bill']['title']).to eq(bill.title)
    end

    it 'returns 403 for regular user' do
      user = create(:user)
      bill = create(:bill)

      get "/bills/#{bill.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /bills
  # ---------------------------------------------------------------------------
  describe 'POST /bills' do
    it 'creates a bill for admin' do
      user = create(:user, :admin)
      post '/bills',
           params: { bill: { title: 'New Bill' } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      expect(json_response['bill']['title']).to eq('New Bill')
      expect(json_response['bill']['status']).to eq('introduced')
    end

    it 'creates a bill for staff' do
      user = create(:user, :with_role, role_name: 'staff')
      post '/bills',
           params: { bill: { title: 'Staff Bill' } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
    end

    it 'creates a bill with optional fields' do
      user = create(:user, :admin)
      post '/bills',
           params: { bill: { title: 'HF 1234 Education', bill_number: 'HF 1234', chamber: 'house', session_year: 2025 } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      expect(json_response['bill']['bill_number']).to eq('HF 1234')
      expect(json_response['bill']['chamber']).to eq('house')
      expect(json_response['bill']['session_year']).to eq(2025)
    end

    it 'creates a bill for manager' do
      user = create(:user, :with_role, role_name: 'manager')
      post '/bills',
           params: { bill: { title: 'Manager Bill' } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
    end

    it 'returns validation errors for missing title' do
      user = create(:user, :admin)
      post '/bills',
           params: { bill: { title: '' } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to be_present
    end

    it 'returns 403 for regular user' do
      user = create(:user)
      post '/bills',
           params: { bill: { title: 'Nope' } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /bills/:id
  # ---------------------------------------------------------------------------
  describe 'PATCH /bills/:id' do
    it 'updates a bill for admin' do
      user = create(:user, :admin)
      bill = create(:bill)

      patch "/bills/#{bill.id}",
            params: { bill: { title: 'Updated Title' } }.to_json,
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['bill']['title']).to eq('Updated Title')
    end

    it 'updates status' do
      user = create(:user, :admin)
      bill = create(:bill)

      patch "/bills/#{bill.id}",
            params: { bill: { status: 'signed' } }.to_json,
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['bill']['status']).to eq('signed')
    end

    it 'returns 403 for regular user' do
      user = create(:user)
      bill = create(:bill)

      patch "/bills/#{bill.id}",
            params: { bill: { title: 'Nope' } }.to_json,
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /bills/:id
  # ---------------------------------------------------------------------------
  describe 'DELETE /bills/:id' do
    it 'deactivates a bill for admin' do
      user = create(:user, :admin)
      bill = create(:bill)

      delete "/bills/#{bill.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(bill.reload.status).to eq('failed')
    end
  end

  # ---------------------------------------------------------------------------
  # POST /bills/:bill_id/issues  /  DELETE /bills/:bill_id/issues/:id
  # ---------------------------------------------------------------------------
  describe 'bill issues linking' do
    let(:admin) { create(:user, :admin) }
    let(:bill)  { create(:bill) }
    let(:issue) { create(:issue) }

    it 'links an issue to a bill' do
      post "/bills/#{bill.id}/issues",
           params: { issue_id: issue.id }.to_json,
           headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['issues'].map { |i| i['id'] }).to include(issue.id)
    end

    it 'returns 422 for duplicate link' do
      create(:bill_issue, bill: bill, issue: issue)

      post "/bills/#{bill.id}/issues",
           params: { issue_id: issue.id }.to_json,
           headers: auth_headers_for(admin)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'unlinks an issue from a bill' do
      create(:bill_issue, bill: bill, issue: issue)

      delete "/bills/#{bill.id}/issues/#{issue.id}", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(bill.reload.issues).not_to include(issue)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /issues/:issue_id/bills  /  DELETE /issues/:issue_id/bills/:id
  # ---------------------------------------------------------------------------
  describe 'issue bills linking' do
    let(:admin) { create(:user, :admin) }
    let(:bill)  { create(:bill) }
    let(:issue) { create(:issue) }

    it 'links a bill to an issue' do
      post "/issues/#{issue.id}/bills",
           params: { bill_id: bill.id }.to_json,
           headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['bills'].map { |b| b['id'] }).to include(bill.id)
    end

    it 'unlinks a bill from an issue' do
      create(:bill_issue, bill: bill, issue: issue)

      delete "/issues/#{issue.id}/bills/#{bill.id}", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(issue.reload.bills).not_to include(bill)
    end
  end

  # ---------------------------------------------------------------------------
  # Bill clients and people
  # ---------------------------------------------------------------------------
  describe 'bill clients linking' do
    let(:admin)  { create(:user, :admin) }
    let(:bill)   { create(:bill) }
    let(:client) { create(:client) }

    it 'links a client to a bill' do
      post "/bills/#{bill.id}/clients",
           params: { client_id: client.id }.to_json,
           headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['clients'].map { |c| c['id'] }).to include(client.id)
    end

    it 'unlinks a client from a bill' do
      create(:bill_client, bill: bill, client: client)

      delete "/bills/#{bill.id}/clients/#{client.id}", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(bill.reload.clients).not_to include(client)
    end
  end

  describe 'bill people linking' do
    let(:admin)  { create(:user, :admin) }
    let(:bill)   { create(:bill) }
    let(:person) { create(:person) }

    it 'adds a person to a bill' do
      post "/bills/#{bill.id}/people",
           params: { person_id: person.id }.to_json,
           headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['people'].map { |p| p['id'] }).to include(person.id)
    end

    it 'removes a person from a bill' do
      create(:bill_person, bill: bill, person: person)

      delete "/bills/#{bill.id}/people/#{person.id}", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(bill.reload.people).not_to include(person)
    end
  end
end
