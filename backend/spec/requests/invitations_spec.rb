require 'rails_helper'

RSpec.describe 'POST /invitations/accept', type: :request do
  let(:admin)  { create(:user, :admin) }
  let(:person) { create(:person, :with_email) }

  def valid_password
    'NewPassword1!'
  end

  def accept_with(token:, password: valid_password, confirmation: valid_password)
    post '/invitations/accept', params: {
      token:                 token,
      password:              password,
      password_confirmation: confirmation
    }.to_json, headers: { 'Content-Type' => 'application/json' }
  end

  it 'creates a user, links the person, returns JWT and user data' do
    raw = Invitation.generate_for(person, invited_by: admin)
    accept_with(token: raw)

    expect(response).to have_http_status(:ok)
    body = json_response
    expect(body['token']).to be_present
    expect(body['refresh_token']).to be_present
    expect(body['user']['email']).to eq(person.email)
    expect(person.reload.user).not_to be_nil
  end

  it 'marks the invitation as accepted' do
    raw = Invitation.generate_for(person, invited_by: admin)
    accept_with(token: raw)

    inv = Invitation.find_by_raw_token(raw)
    expect(inv.accepted_at).not_to be_nil
  end

  it 'confirms the user automatically (no email confirmation required)' do
    raw = Invitation.generate_for(person, invited_by: admin)
    accept_with(token: raw)

    user = person.reload.user
    expect(user.confirmed_at).not_to be_nil
  end

  it 'returns 422 for an invalid token' do
    accept_with(token: 'bogustoken')
    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response['errors'].first).to match(/invalid or has expired/i)
  end

  it 'returns 422 for an expired token' do
    raw = Invitation.generate_for(person, invited_by: admin)
    Invitation.find_by(token_digest: Digest::SHA256.hexdigest(raw))
              .update!(expires_at: 1.minute.ago)

    accept_with(token: raw)
    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response['errors'].first).to match(/invalid or has expired/i)
  end

  it 'returns 422 for a revoked token' do
    raw = Invitation.generate_for(person, invited_by: admin)
    Invitation.find_by(token_digest: Digest::SHA256.hexdigest(raw)).revoke!

    accept_with(token: raw)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'returns 422 for a weak password' do
    raw = Invitation.generate_for(person, invited_by: admin)
    accept_with(token: raw, password: 'weak', confirmation: 'weak')

    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response['errors']).to be_present
    expect(person.reload.user_id).to be_nil
  end

  it 'returns 422 when passwords do not match' do
    raw = Invitation.generate_for(person, invited_by: admin)
    accept_with(token: raw, password: valid_password, confirmation: 'Mismatch123!')

    expect(response).to have_http_status(:unprocessable_content)
    expect(person.reload.user_id).to be_nil
  end

  it 'does not require authentication' do
    raw = Invitation.generate_for(person, invited_by: admin)
    # No auth headers — should still succeed
    accept_with(token: raw)
    expect(response).to have_http_status(:ok)
  end
end
