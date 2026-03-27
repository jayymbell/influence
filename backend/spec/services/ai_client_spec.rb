require 'rails_helper'

RSpec.describe AiClient do
  describe '.prompt' do
    let(:ai_url) { "#{described_class::AI_SERVICE_URL}/ai/prompt" }

    it 'returns the result from the AI service' do
      stub_request(:post, ai_url)
        .with(body: { prompt: 'Hello' }.to_json)
        .to_return(
          status: 200,
          body: { result: 'Hi there!' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = described_class.prompt('Hello')
      expect(result).to eq('Hi there!')
    end

    it 'raises AiServiceError on non-200 response' do
      stub_request(:post, ai_url)
        .to_return(status: 500, body: 'Internal error')

      expect { described_class.prompt('fail') }
        .to raise_error(AiClient::AiServiceError, /500/)
    end

    it 'raises AiServiceError when service is unreachable' do
      stub_request(:post, ai_url).to_timeout

      expect { described_class.prompt('fail') }
        .to raise_error(AiClient::AiServiceError, /Could not reach AI service/)
    end
  end
end
