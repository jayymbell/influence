require 'rails_helper'

RSpec.describe 'People API', type: :request do
  describe 'GET /people' do
    it 'returns people for admin users' do
      user = create(:user, :admin)
      create_list(:person, 3)
      get '/people', headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body['message']).to match(/People found/i)
      expect(body['people'].length).to eq(3)
    end

    it 'returns people for staff users' do
      user = create(:user, :with_role, role_name: 'staff')
      create_list(:person, 2)
      get '/people', headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['people'].length).to eq(2)
    end

    it 'returns 403 for unauthorized users' do
      user = create(:user)
      get '/people', headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 401 for unauthenticated requests' do
      get '/people'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'filters by query' do
      user = create(:user, :admin)
      create(:person, display_name: 'Alice Smith')
      create(:person, display_name: 'Bob Jones')
      get '/people', params: { query: 'alice' }, headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body['people'].length).to eq(1)
      expect(body['people'].first['display_name']).to eq('Alice Smith')
    end

    it 'excludes discarded people by default' do
      user = create(:user, :admin)
      create(:person)
      create(:person, :discarded)
      get '/people', headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['people'].length).to eq(1)
    end

    it 'returns discarded people when discarded param is true' do
      user = create(:user, :admin)
      create(:person)
      create(:person, :discarded)
      get '/people', params: { discarded: 'true' }, headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['people'].length).to eq(1)
      expect(json_response['people'].first['discarded_at']).not_to be_nil
    end
  end

  describe 'GET /people/:id' do
    it 'returns a person for admin' do
      user = create(:user, :admin)
      person = create(:person)
      get "/people/#{person.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body['message']).to match(/Person found/i)
      expect(body['person']['id']).to eq(person.id)
    end

    it 'returns 404 when person does not exist' do
      user = create(:user, :admin)
      get '/people/99999', headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 403 for unauthorized users' do
      user = create(:user)
      person = create(:person)
      get "/people/#{person.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /people' do
    let(:valid_params) do
      { person: { first_name: 'Jane', last_name: 'Doe', display_name: 'Jane Doe' } }.to_json
    end

    it 'creates a person for admin' do
      user = create(:user, :admin)
      post '/people', params: valid_params, headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      body = json_response
      expect(body['message']).to match(/Person created/i)
      expect(body['person']['display_name']).to eq('Jane Doe')
    end

    it 'sets created_by to current user' do
      user = create(:user, :admin)
      post '/people', params: valid_params, headers: auth_headers_for(user)

      person = Person.last
      expect(person.created_by).to eq(user)
    end

    it 'returns 422 when required fields are missing' do
      user = create(:user, :admin)
      post '/people',
           params: { person: { first_name: 'Only' } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors']).to be_present
    end

    it 'allows a regular user to create their own person' do
      user = create(:user)
      post '/people', params: valid_params, headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      expect(json_response['person']['first_name']).to eq('Jane')
      expect(Person.last.user).to eq(user)
    end

    it 'automatically links the person to the current regular user' do
      user = create(:user)
      post '/people', params: valid_params, headers: auth_headers_for(user)

      expect(Person.last.user_id).to eq(user.id)
    end

    it 'automatically sets email from current user for regular users' do
      user = create(:user)
      post '/people', params: valid_params, headers: auth_headers_for(user)

      expect(Person.last.email).to eq(user.email)
    end
  end

  describe 'PATCH /people/:id' do
    it 'updates a person for admin' do
      user = create(:user, :admin)
      person = create(:person, display_name: 'Old Name')
      patch "/people/#{person.id}",
            params: { person: { display_name: 'New Name' } }.to_json,
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['person']['display_name']).to eq('New Name')
    end

    it 'sets updated_by to current user' do
      user = create(:user, :admin)
      person = create(:person)
      patch "/people/#{person.id}",
            params: { person: { display_name: 'Updated' } }.to_json,
            headers: auth_headers_for(user)

      expect(person.reload.updated_by).to eq(user)
    end

    it 'returns 422 on invalid data' do
      user = create(:user, :admin)
      person = create(:person)
      patch "/people/#{person.id}",
            params: { person: { email: 'not-valid' } }.to_json,
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors']).to be_present
    end

    it 'returns 403 for unauthorized users' do
      user = create(:user)
      person = create(:person)
      patch "/people/#{person.id}",
            params: { person: { display_name: 'Hack' } }.to_json,
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /people/:id' do
    it 'soft deletes a person for admin' do
      user = create(:user, :admin)
      person = create(:person)
      delete "/people/#{person.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to match(/deactivated/i)
      expect(person.reload.discarded_at).to be_present
      expect(person.reload.deactivated_by).to eq(user)
    end

    it 'excludes discarded person from default scope' do
      user = create(:user, :admin)
      person = create(:person)
      delete "/people/#{person.id}", headers: auth_headers_for(user)

      get '/people', headers: auth_headers_for(user)
      ids = json_response['people'].map { |p| p['id'] }
      expect(ids).not_to include(person.id)
    end

    it 'returns 403 for unauthorized users' do
      user = create(:user)
      person = create(:person)
      delete "/people/#{person.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /people/:id/invite' do
    let(:admin)  { create(:user, :admin) }
    let(:person) { create(:person, :with_email) }

    it 'sends an invitation and returns 200' do
      post "/people/#{person.id}/invite", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to match(/invitation sent/i)
      expect(person.invitations.active.count).to eq(1)
    end

    it 'enqueues the invitation email' do
      expect {
        post "/people/#{person.id}/invite", headers: auth_headers_for(admin)
      }.to have_enqueued_mail(InvitationsMailer, :invite)
    end

    it 'returns 422 when person has no email' do
      person_no_email = create(:person, email: nil)
      post "/people/#{person_no_email.id}/invite", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors'].first).to match(/no email/i)
    end

    it 'returns 422 when person already has a user account' do
      existing_user = create(:user)
      person_with_user = create(:person, user: existing_user, email: existing_user.email)
      post "/people/#{person_with_user.id}/invite", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors'].first).to match(/already has a user/i)
    end

    it 'revokes the old invitation when re-inviting' do
      post "/people/#{person.id}/invite", headers: auth_headers_for(admin)
      first_inv = person.invitations.active.first

      post "/people/#{person.id}/invite", headers: auth_headers_for(admin)

      expect(first_inv.reload.revoked_at).not_to be_nil
      expect(person.invitations.active.count).to eq(1)
    end

    it 'returns 403 for regular users' do
      user = create(:user)
      post "/people/#{person.id}/invite", headers: auth_headers_for(user)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /people/:id/invitation' do
    let(:admin)  { create(:user, :admin) }
    let(:person) { create(:person, :with_email) }

    it 'revokes the active invitation' do
      Invitation.generate_for(person, invited_by: admin)
      expect(person.invitations.active.count).to eq(1)

      delete "/people/#{person.id}/invitation", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to match(/revoked/i)
      expect(person.invitations.active.count).to eq(0)
    end

    it 'returns 422 when there is no active invitation' do
      delete "/people/#{person.id}/invitation", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors'].first).to match(/no active invitation/i)
    end

    it 'returns 403 for regular users' do
      user = create(:user)
      delete "/people/#{person.id}/invitation", headers: auth_headers_for(user)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
