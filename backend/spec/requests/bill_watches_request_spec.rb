# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bill Watches API', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:bill)  { create(:bill) }

  # ---------------------------------------------------------------------------
  # POST /bills/:id/watch
  # ---------------------------------------------------------------------------
  describe 'POST /bills/:id/watch' do
    it 'creates a watch record for an authenticated user' do
      post "/bills/#{bill.id}/watch", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:created)
      expect(json_response['watched']).to be true
      expect(BillWatch.exists?(user: admin, bill: bill)).to be true
    end

    it 'is idempotent — returns 200 and watched:true if already watching' do
      create(:bill_watch, user: admin, bill: bill)

      post "/bills/#{bill.id}/watch", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['watched']).to be true
      expect(BillWatch.where(user: admin, bill: bill).count).to eq(1)
    end

    it 'returns 401 for unauthenticated requests' do
      post "/bills/#{bill.id}/watch"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /bills/:id/unwatch
  # ---------------------------------------------------------------------------
  describe 'DELETE /bills/:id/unwatch' do
    it 'removes the watch record for an authenticated user' do
      create(:bill_watch, user: admin, bill: bill)

      delete "/bills/#{bill.id}/unwatch", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['watched']).to be false
      expect(BillWatch.exists?(user: admin, bill: bill)).to be false
    end

    it 'returns 404 when not watching the bill' do
      delete "/bills/#{bill.id}/unwatch", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 for unauthenticated requests' do
      delete "/bills/#{bill.id}/unwatch"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ---------------------------------------------------------------------------
  # watched_by_current_user in bill serializer
  # ---------------------------------------------------------------------------
  describe 'GET /bills/:id — watched_by_current_user' do
    it 'returns watched_by_current_user: true when the user is watching the bill' do
      create(:bill_watch, user: admin, bill: bill)

      get "/bills/#{bill.id}", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['bill']['watched_by_current_user']).to be true
    end

    it 'returns watched_by_current_user: false when not watching' do
      get "/bills/#{bill.id}", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['bill']['watched_by_current_user']).to be false
    end
  end

  # ---------------------------------------------------------------------------
  # GET /bills?watched=true
  # ---------------------------------------------------------------------------
  describe 'GET /bills?watched=true' do
    it 'returns only bills watched by the current user' do
      watched_bill   = create(:bill)
      unwatched_bill = create(:bill)
      create(:bill_watch, user: admin, bill: watched_bill)

      get '/bills', params: { watched: 'true' }, headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      ids = json_response['bills'].map { |b| b['id'] }
      expect(ids).to include(watched_bill.id)
      expect(ids).not_to include(unwatched_bill.id)
    end
  end
end
