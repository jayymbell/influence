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

  # ---------------------------------------------------------------------------
  # Open States integration endpoints
  # ---------------------------------------------------------------------------

  let(:open_states_base) { "https://v3.openstates.org" }

  before do
    stub_const("BillImportService::API_KEY", "test-key")
  end

  def open_states_bill_payload(id: "ocd-bill/1", identifier: "HF 100", title: "Test Bill", chamber: "lower", session: "2026")
    {
      "id"               => id,
      "identifier"       => identifier,
      "title"            => title,
      "openstates_url"   => "https://openstates.org/mn/bills/#{session}/#{identifier.delete(' ')}/",
      "from_organization" => { "classification" => chamber },
      "session"          => session,
      "subject"          => ["Environment"],
      "abstracts"        => [ { "abstract" => "Test description.", "note" => "" } ]
    }
  end

  def stub_os_search(query:, results: nil, status: 200)
    results ||= [ open_states_bill_payload ]
    stub_request(:get, "#{open_states_base}/bills")
      .with(query: hash_including("q" => query, "jurisdiction" => "mn"))
      .to_return(status: status, body: { "results" => results, "pagination" => { "total_items" => results.size } }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  def stub_os_fetch(external_id: "ocd-bill/1", body: nil, status: 200)
    body ||= open_states_bill_payload(id: external_id)
    escaped = CGI.escape(external_id)
    stub_request(:get, Regexp.new("v3\\.openstates\\.org/bills/#{Regexp.escape(escaped)}"))
      .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  # ---------------------------------------------------------------------------
  # GET /bills/search
  # ---------------------------------------------------------------------------
  describe 'GET /bills/search' do
    let(:admin) { create(:user, :admin) }

    it 'returns normalized search results for an admin' do
      stub_os_search(query: "HF 100")

      get '/bills/search', params: { q: "HF 100" }, headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['results']).to be_an(Array)
      expect(json_response['results'].first['bill_number']).to eq "HF 100"
    end

    it 'marks already_imported correctly' do
      create(:bill, external_id: "ocd-bill/1")
      stub_os_search(query: "HF 100")

      get '/bills/search', params: { q: "HF 100" }, headers: auth_headers_for(admin)

      expect(json_response['results'].first['already_imported']).to be true
    end

    it 'returns 400 when q param is missing' do
      get '/bills/search', headers: auth_headers_for(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns 401 without authentication' do
      get '/bills/search', params: { q: "test" }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 403 for non-privileged user' do
      user = create(:user)
      get '/bills/search', params: { q: "test" }, headers: auth_headers_for(user)
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 502 when Open States is unavailable' do
      stub_request(:get, /v3\.openstates\.org\/bills/).to_return(status: 503, body: "error")
      get '/bills/search', params: { q: "fail" }, headers: auth_headers_for(admin)
      expect(response).to have_http_status(:bad_gateway)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /bills/import
  # ---------------------------------------------------------------------------
  describe 'POST /bills/import' do
    let(:admin) { create(:user, :admin) }

    it 'creates and returns a new bill for admin' do
      stub_os_fetch(external_id: "ocd-bill/1")

      post '/bills/import',
           params: { external_id: "ocd-bill/1" }.to_json,
           headers: auth_headers_for(admin)

      expect(response).to have_http_status(:created)
      expect(json_response['bill']['external_id']).to eq "ocd-bill/1"
      expect(json_response['bill']['bill_number']).to eq "HF 100"
    end

    it 'is idempotent — returns existing bill at 200 if already imported' do
      existing = create(:bill, external_id: "ocd-bill/1")

      post '/bills/import',
           params: { external_id: "ocd-bill/1" }.to_json,
           headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['bill']['id']).to eq existing.id
      expect(WebMock).not_to have_requested(:get, /openstates/)
    end

    it 'returns 400 when external_id is missing' do
      post '/bills/import', params: {}.to_json, headers: auth_headers_for(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns 401 without authentication' do
      post '/bills/import', params: { external_id: "ocd-bill/1" }.to_json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 403 for non-privileged user' do
      user = create(:user)
      post '/bills/import',
           params: { external_id: "ocd-bill/1" }.to_json,
           headers: auth_headers_for(user)
      expect(response).to have_http_status(:forbidden)
    end

    it 'works for a manager' do
      manager = create(:user, :with_role, role_name: 'manager')
      stub_os_fetch(external_id: "ocd-bill/new")

      post '/bills/import',
           params: { external_id: "ocd-bill/new" }.to_json,
           headers: auth_headers_for(manager)

      expect(response).to have_http_status(:created)
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /bills/:id/link_external
  # ---------------------------------------------------------------------------
  describe 'PATCH /bills/:id/link_external' do
    let(:admin)        { create(:user, :admin) }
    let(:bill)         { create(:bill) }

    it 'links bill to Open States and returns updated bill' do
      stub_os_fetch(external_id: "ocd-bill/1")

      patch "/bills/#{bill.id}/link_external",
            params: { external_id: "ocd-bill/1" }.to_json,
            headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['bill']['external_id']).to eq "ocd-bill/1"
      expect(json_response['bill']['last_synced_at']).not_to be_nil
    end

    it 'returns 422 when external_id is already linked to another bill' do
      create(:bill, external_id: "ocd-bill/1")

      patch "/bills/#{bill.id}/link_external",
            params: { external_id: "ocd-bill/1" }.to_json,
            headers: auth_headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors'].first).to match(/already linked/i)
    end

    it 'returns 403 for manager not on bill' do
      manager = create(:user, :with_role, role_name: 'manager')

      patch "/bills/#{bill.id}/link_external",
            params: { external_id: "ocd-bill/x" }.to_json,
            headers: auth_headers_for(manager)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 401 without authentication' do
      patch "/bills/#{bill.id}/link_external", params: { external_id: "ocd-bill/1" }.to_json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /bills/:id/refresh
  # ---------------------------------------------------------------------------
  describe 'POST /bills/:id/refresh' do
    let(:admin) { create(:user, :admin) }
    let(:bill)  { create(:bill, external_id: "ocd-bill/1", title: "Old Title") }

    it 'refreshes bill fields from Open States' do
      stub_os_fetch(
        external_id: "ocd-bill/1",
        body: open_states_bill_payload(id: "ocd-bill/1", title: "New Title")
      )

      post "/bills/#{bill.id}/refresh", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['bill']['title']).to eq "New Title"
      expect(json_response['bill']['last_synced_at']).not_to be_nil
    end

    it 'returns 422 when bill has no external_id' do
      unlinked = create(:bill)

      post "/bills/#{unlinked.id}/refresh", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors'].first).to match(/not linked/i)
    end

    it 'returns 403 for manager not on bill' do
      manager = create(:user, :with_role, role_name: 'manager')

      post "/bills/#{bill.id}/refresh", headers: auth_headers_for(manager)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 401 without authentication' do
      post "/bills/#{bill.id}/refresh"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 502 when Open States is unavailable' do
      stub_request(:get, Regexp.new("v3\\.openstates\\.org/bills/#{Regexp.escape(CGI.escape('ocd-bill/1'))}"))
        .to_return(status: 503, body: "error")

      post "/bills/#{bill.id}/refresh", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:bad_gateway)
    end
  end

end
