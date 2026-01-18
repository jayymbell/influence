module JwtHelpers
  def jwt_token_for(user)
  # Older warden-jwt_auth versions expect 3 arguments: (user, scope, aud)
  Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  def auth_headers_for(user)
    { 'Authorization' => "Bearer #{jwt_token_for(user)}", 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  end
end

RSpec.configure do |config|
  config.include JwtHelpers, type: :request
end
