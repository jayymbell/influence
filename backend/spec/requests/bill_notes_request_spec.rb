# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bill Notes API', type: :request do
  let(:admin)   { create(:user, :admin) }
  let(:staff)   { create(:user, :with_role, role_name: 'staff') }
  let(:bill)    { create(:bill) }

  # ---------------------------------------------------------------------------
  # GET /bills/:bill_id/notes
  # ---------------------------------------------------------------------------
  describe 'GET /bills/:bill_id/notes' do
    it 'returns notes for the bill' do
      create(:bill_note, bill: bill, user: admin, title: 'First note')
      create(:bill_note, :shared, bill: bill, user: staff, title: 'Second note')

      get "/bills/#{bill.id}/notes", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['notes'].length).to eq(2)
      expect(json_response['notes'].first).to include('content', 'author', 'created_at')
    end

    it 'returns 401 for unauthenticated requests' do
      get "/bills/#{bill.id}/notes"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /bills/:bill_id/notes
  # ---------------------------------------------------------------------------
  describe 'POST /bills/:bill_id/notes' do
    it 'creates a note on the bill' do
      post "/bills/#{bill.id}/notes",
           params: { note: { title: 'My note', content: '<p>Hello world</p>' } }.to_json,
           headers: auth_headers_for(admin)

      expect(response).to have_http_status(:created)
      expect(json_response['note']['title']).to eq('My note')
      expect(json_response['note']['content']).to eq('<p>Hello world</p>')
      expect(json_response['note']['author']).to be_present
      expect(BillNote.count).to eq(1)
    end

    it 'returns an error when content is missing' do
      post "/bills/#{bill.id}/notes",
           params: { note: { title: 'Empty', content: '' } }.to_json,
           headers: auth_headers_for(admin)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 401 for unauthenticated requests' do
      post "/bills/#{bill.id}/notes", params: { note: { content: '<p>Hi</p>' } }.to_json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /bills/:bill_id/notes/:id
  # ---------------------------------------------------------------------------
  describe 'PATCH /bills/:bill_id/notes/:id' do
    it 'allows the author to update their note' do
      note = create(:bill_note, bill: bill, user: admin, title: 'Original', content: '<p>Old</p>')

      patch "/bills/#{bill.id}/notes/#{note.id}",
            params: { note: { title: 'Updated', content: '<p>New</p>' } }.to_json,
            headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['note']['title']).to eq('Updated')
      expect(json_response['note']['content']).to eq('<p>New</p>')
    end

    it 'allows admins to update any note' do
      other_user = create(:user, :with_role, role_name: 'staff')
      note = create(:bill_note, bill: bill, user: other_user)

      patch "/bills/#{bill.id}/notes/#{note.id}",
            params: { note: { content: '<p>Admin edit</p>' } }.to_json,
            headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
    end

    it 'denies a different non-admin/staff user from updating the note' do
      manager = create(:user, :with_role, role_name: 'manager')
      note = create(:bill_note, bill: bill, user: admin)

      patch "/bills/#{bill.id}/notes/#{note.id}",
            params: { note: { content: '<p>Unauthorized edit</p>' } }.to_json,
            headers: auth_headers_for(manager)

      expect(response).to have_http_status(:forbidden)
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /bills/:bill_id/notes/:id
  # ---------------------------------------------------------------------------
  describe 'DELETE /bills/:bill_id/notes/:id' do
    it 'allows the author to delete their note' do
      note = create(:bill_note, bill: bill, user: admin)

      delete "/bills/#{bill.id}/notes/#{note.id}", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(BillNote.exists?(note.id)).to be false
    end

    it 'allows admins to delete any note' do
      other_user = create(:user, :with_role, role_name: 'staff')
      note = create(:bill_note, bill: bill, user: other_user)

      delete "/bills/#{bill.id}/notes/#{note.id}", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
    end

    it 'denies a different non-admin/staff user from deleting the note' do
      manager = create(:user, :with_role, role_name: 'manager')
      note = create(:bill_note, bill: bill, user: admin)

      delete "/bills/#{bill.id}/notes/#{note.id}", headers: auth_headers_for(manager)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 401 for unauthenticated requests' do
      note = create(:bill_note, bill: bill, user: admin)
      delete "/bills/#{bill.id}/notes/#{note.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /bills/:bill_id/notes/:id
  # ---------------------------------------------------------------------------
  describe 'GET /bills/:bill_id/notes/:id' do
    it 'returns a shared note to any authenticated user with bill access' do
      note = create(:bill_note, :shared, bill: bill, user: staff, title: 'Shared note')
      manager = create(:user, :with_role, role_name: 'manager')

      get "/bills/#{bill.id}/notes/#{note.id}", headers: auth_headers_for(manager)

      expect(response).to have_http_status(:ok)
      expect(json_response['note']['id']).to eq(note.id)
      expect(json_response['note']['shared']).to be true
    end

    it 'returns an unshared note to its author' do
      note = create(:bill_note, bill: bill, user: admin, title: 'Private note')

      get "/bills/#{bill.id}/notes/#{note.id}", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['note']['id']).to eq(note.id)
    end

    it 'denies access to an unshared note for non-authors' do
      manager = create(:user, :with_role, role_name: 'manager')
      note = create(:bill_note, bill: bill, user: admin, title: 'Private note')

      get "/bills/#{bill.id}/notes/#{note.id}", headers: auth_headers_for(manager)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 401 for unauthenticated requests' do
      note = create(:bill_note, :shared, bill: bill, user: admin)
      get "/bills/#{bill.id}/notes/#{note.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /bills/:bill_id/notes — visibility
  # ---------------------------------------------------------------------------
  describe 'GET /bills/:bill_id/notes — visibility' do
    it 'returns own unshared notes and shared notes, but not others\' unshared notes' do
      own_note    = create(:bill_note,         bill: bill, user: admin, title: 'My private note')
      shared_note = create(:bill_note, :shared, bill: bill, user: staff, title: 'Shared note')
      other_note  = create(:bill_note,         bill: bill, user: staff, title: 'Other private note')

      get "/bills/#{bill.id}/notes", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      ids = json_response['notes'].map { |n| n['id'] }
      expect(ids).to include(own_note.id, shared_note.id)
      expect(ids).not_to include(other_note.id)
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /bills/:bill_id/notes/:id/share
  # ---------------------------------------------------------------------------
  describe 'PATCH /bills/:bill_id/notes/:id/share' do
    it 'allows the author to share their note' do
      note = create(:bill_note, bill: bill, user: admin)

      patch "/bills/#{bill.id}/notes/#{note.id}/share", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['note']['shared']).to be true
      expect(note.reload.shared).to be true
    end

    it 'allows admin/staff to share any note' do
      note = create(:bill_note, bill: bill, user: staff)

      patch "/bills/#{bill.id}/notes/#{note.id}/share", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(note.reload.shared).to be true
    end

    it 'denies a manager who did not author the note' do
      manager = create(:user, :with_role, role_name: 'manager')
      note = create(:bill_note, bill: bill, user: admin)

      patch "/bills/#{bill.id}/notes/#{note.id}/share", headers: auth_headers_for(manager)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 401 for unauthenticated requests' do
      note = create(:bill_note, bill: bill, user: admin)
      patch "/bills/#{bill.id}/notes/#{note.id}/share"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /bills/:bill_id/notes/:id/unshare
  # ---------------------------------------------------------------------------
  describe 'PATCH /bills/:bill_id/notes/:id/unshare' do
    it 'allows the author to unshare their note' do
      note = create(:bill_note, :shared, bill: bill, user: admin)

      patch "/bills/#{bill.id}/notes/#{note.id}/unshare", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['note']['shared']).to be false
      expect(note.reload.shared).to be false
    end

    it 'allows admin to unshare any note' do
      note = create(:bill_note, :shared, bill: bill, user: staff)

      patch "/bills/#{bill.id}/notes/#{note.id}/unshare", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(note.reload.shared).to be false
    end

    it 'denies staff from unsharing another user\'s note' do
      other_staff = create(:user, :with_role, role_name: 'staff')
      note = create(:bill_note, :shared, bill: bill, user: admin)

      patch "/bills/#{bill.id}/notes/#{note.id}/unshare", headers: auth_headers_for(other_staff)

      expect(response).to have_http_status(:forbidden)
    end

    it 'denies a manager who did not author the note' do
      manager = create(:user, :with_role, role_name: 'manager')
      note = create(:bill_note, :shared, bill: bill, user: admin)

      patch "/bills/#{bill.id}/notes/#{note.id}/unshare", headers: auth_headers_for(manager)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 401 for unauthenticated requests' do
      note = create(:bill_note, :shared, bill: bill, user: admin)
      patch "/bills/#{bill.id}/notes/#{note.id}/unshare"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /bills/:bill_id/notes/:id/pin
  # ---------------------------------------------------------------------------
  describe 'PATCH /bills/:bill_id/notes/:id/pin' do
    it 'allows admin to pin a shared note' do
      note = create(:bill_note, :shared, bill: bill, user: staff)

      patch "/bills/#{bill.id}/notes/#{note.id}/pin", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['note']['pinned']).to be true
      expect(note.reload.pinned).to be true
    end

    it 'returns an error when trying to pin an unshared note' do
      note = create(:bill_note, bill: bill, user: admin)

      patch "/bills/#{bill.id}/notes/#{note.id}/pin", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(note.reload.pinned).to be false
    end

    it 'denies a non-admin/staff user' do
      manager = create(:user, :with_role, role_name: 'manager')
      note = create(:bill_note, :shared, bill: bill, user: admin)

      patch "/bills/#{bill.id}/notes/#{note.id}/pin", headers: auth_headers_for(manager)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 401 for unauthenticated requests' do
      note = create(:bill_note, :shared, bill: bill, user: admin)
      patch "/bills/#{bill.id}/notes/#{note.id}/pin"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /bills/:bill_id/notes/:id/unpin
  # ---------------------------------------------------------------------------
  describe 'PATCH /bills/:bill_id/notes/:id/unpin' do
    it 'allows admin to unpin a pinned note' do
      note = create(:bill_note, :pinned, bill: bill, user: staff)

      patch "/bills/#{bill.id}/notes/#{note.id}/unpin", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['note']['pinned']).to be false
      expect(note.reload.pinned).to be false
    end

    it 'denies a non-admin/staff user' do
      manager = create(:user, :with_role, role_name: 'manager')
      note = create(:bill_note, :pinned, bill: bill, user: admin)

      patch "/bills/#{bill.id}/notes/#{note.id}/unpin", headers: auth_headers_for(manager)

      expect(response).to have_http_status(:forbidden)
    end
  end

  # ---------------------------------------------------------------------------
  # Unsharing a pinned note auto-unpins it
  # ---------------------------------------------------------------------------
  describe 'unsharing a pinned note' do
    it 'automatically unpins the note when it is unshared' do
      note = create(:bill_note, :pinned, bill: bill, user: admin)

      patch "/bills/#{bill.id}/notes/#{note.id}/unshare", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['note']['pinned']).to be false
      expect(note.reload.pinned).to be false
    end
  end
end
