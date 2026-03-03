# Service for communicating with the AI FastAPI service.
#
# Calls POST /ai/prompt on the AI service and returns the result.
# In production the AI service runs as a Docker Compose sibling at
# http://ai:8000.  Override with the AI_SERVICE_URL env var.
class AiClient
  AI_SERVICE_URL = ENV.fetch("AI_SERVICE_URL", "http://ai:8000")

  class AiServiceError < StandardError; end

  # Send a prompt to the general assistant and return the response text.
  #
  # @param prompt [String] the user's message
  # @return [String] the assistant's answer
  # @raise [AiServiceError] when the AI service is unreachable or returns an error
  def self.prompt(prompt)
    uri = URI("#{AI_SERVICE_URL}/ai/prompt")
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 10
    http.read_timeout = 120 # LLM calls can be slow

    request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    request.body = { prompt: prompt }.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise AiServiceError, "AI service returned #{response.code}: #{response.body}"
    end

    parsed = JSON.parse(response.body)
    parsed["result"]
  rescue Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    raise AiServiceError, "Could not reach AI service: #{e.message}"
  end
end
