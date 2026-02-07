require 'rails_helper'

RSpec.describe 'Health check', type: :request do
  it 'returns 200 on GET /up' do
    get '/up'
    expect(response).to have_http_status(:ok)
    # The health endpoint may render plain text or HTML depending on stack.
    expect(response.body).to be_present
  end
end
