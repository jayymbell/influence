# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users::Registrations API', type: :request do
  describe 'PATCH /signup (account update)' do
    let(:password) { 'Password123!@' }
    let(:user) { create(:user, password: password, password_confirmation: password) }

    context 'when updating email' do
      it 'returns ok and sets unconfirmed_email (person email syncs on confirmation)' do
        new_email = 'newemail@example.com'

        patch '/signup',
              params: { user: { email: new_email, current_password: password } }.to_json,
              headers: auth_headers_for(user).merge(json_headers)

        expect(response).to have_http_status(:ok)
        expect(user.reload.unconfirmed_email).to eq(new_email)
      end

      it 'succeeds when user has no linked person' do
        patch '/signup',
              params: { user: { email: 'newemail2@example.com', current_password: password } }.to_json,
              headers: auth_headers_for(user).merge(json_headers)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when updating password' do
      it 'returns ok' do
        new_password = 'NewPassword456!@'

        patch '/signup',
              params: {
                user: {
                  password: new_password,
                  password_confirmation: new_password,
                  current_password: password
                }
              }.to_json,
              headers: auth_headers_for(user).merge(json_headers)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with wrong current password' do
      it 'returns 422' do
        patch '/signup',
              params: { user: { email: 'other@example.com', current_password: 'wrong' } }.to_json,
              headers: auth_headers_for(user).merge(json_headers)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it 'returns 401 when unauthenticated' do
      patch '/signup',
            params: { user: { email: 'x@example.com', current_password: password } }.to_json,
            headers: json_headers

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'Email confirmation — person email sync' do
    it 'syncs person email when user confirms their new email address' do
      password = 'Password123!@'
      user = create(:user, password: password, password_confirmation: password, confirmed_at: Time.current)
      person = create(:person, user: user, email: user.email)

      # Simulate Devise reconfirmable: store digested token and unconfirmed_email
      raw, enc = Devise.token_generator.generate(User, :confirmation_token)
      user.update!(
        confirmation_token: enc,
        confirmation_sent_at: Time.current,
        unconfirmed_email: 'confirmed@example.com'
      )

      get "/confirmation?confirmation_token=#{raw}"

      expect(user.reload.email).to eq('confirmed@example.com')
      expect(person.reload.email).to eq('confirmed@example.com')
    end
  end
end
