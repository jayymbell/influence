require 'rails_helper'

RSpec.describe 'Conversations API', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'GET /conversations' do
    it 'returns the current user\'s conversations' do
      create(:conversation, user: user, title: 'Mine')
      create(:conversation, user: other_user, title: 'Not mine')

      get '/conversations', headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body['conversations'].length).to eq(1)
      expect(body['conversations'].first['title']).to eq('Mine')
    end

    it 'returns 401 when not authenticated' do
      get '/conversations'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /conversations/:id' do
    it 'returns the conversation with messages' do
      conversation = create(:conversation, :with_messages, user: user)

      get "/conversations/#{conversation.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body['conversation']).to be_present
      expect(body['conversation']['messages']).to be_an(Array)
    end

    it 'returns 403 for another user\'s conversation' do
      other_conv = create(:conversation, user: other_user)

      get "/conversations/#{other_conv.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /conversations' do
    it 'creates a new conversation' do
      post '/conversations',
           params: { conversation: { title: 'New chat' } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      body = json_response
      expect(body['conversation']['title']).to eq('New chat')
      expect(Conversation.count).to eq(1)
      expect(Conversation.first.user).to eq(user)
    end
  end

  describe 'PATCH /conversations/:id' do
    it 'updates the conversation title' do
      conversation = create(:conversation, user: user, title: 'Old')

      patch "/conversations/#{conversation.id}",
            params: { conversation: { title: 'New title' } }.to_json,
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(conversation.reload.title).to eq('New title')
    end
  end

  describe 'DELETE /conversations/:id' do
    it 'deletes the conversation' do
      conversation = create(:conversation, user: user)

      delete "/conversations/#{conversation.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(Conversation.exists?(conversation.id)).to be(false)
    end

    it 'returns 403 for another user\'s conversation' do
      other_conv = create(:conversation, user: other_user)

      delete "/conversations/#{other_conv.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /conversations/:id/messages' do
    let(:conversation) { create(:conversation, user: user) }
    let(:ai_url) { "#{AiClient::AI_SERVICE_URL}/ai/prompt" }

    it 'sends a message and returns the AI response' do
      stub_request(:post, ai_url)
        .to_return(
          status: 200,
          body: { result: 'I am the assistant.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      post "/conversations/#{conversation.id}/messages",
           params: { message: { content: 'Hello AI' } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      body = json_response
      messages = body['conversation']['messages']
      expect(messages.length).to eq(2)
      expect(messages.first['role']).to eq('user')
      expect(messages.first['content']).to eq('Hello AI')
      expect(messages.last['role']).to eq('assistant')
      expect(messages.last['content']).to eq('I am the assistant.')
    end

    it 'auto-generates a title from the first message' do
      conversation.update!(title: nil)

      stub_request(:post, ai_url)
        .to_return(
          status: 200,
          body: { result: 'Reply' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      post "/conversations/#{conversation.id}/messages",
           params: { message: { content: 'What is Rails?' } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(conversation.reload.title).to eq('What is Rails?')
    end

    it 'returns 502 when AI service is down' do
      stub_request(:post, ai_url).to_timeout

      post "/conversations/#{conversation.id}/messages",
           params: { message: { content: 'Hello' } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:bad_gateway)
      body = json_response
      expect(body['errors']).to be_present
    end

    it 'returns 422 when message content is blank' do
      post "/conversations/#{conversation.id}/messages",
           params: { message: { content: '' } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns 403 for another user\'s conversation' do
      other_conv = create(:conversation, user: other_user)

      post "/conversations/#{other_conv.id}/messages",
           params: { message: { content: 'Snoop' } }.to_json,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
