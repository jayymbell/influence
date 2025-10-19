class Rack::Attack
  ### Configure Cache ###
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Spammy Clients ###
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  ### Prevent Brute-Force Login Attacks ###
  throttle('login/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/login' && req.post?
      req.ip
    end
  end

  # Rate limit by IP only, removing email-based throttling
  throttle('auth/ip', limit: 20, period: 5.minutes) do |req|
    if (req.path == '/login' || req.path == '/signup') && req.post?
      req.ip
    end
  end

  # Throttle password reset attempts
  throttle('password-reset/ip', limit: 3, period: 15.minutes) do |req|
    if req.path == '/password' && req.post?
      req.ip
    end
  end

  # Throttle account creation
  throttle('signup/ip', limit: 3, period: 1.hour) do |req|
    if req.path == '/signup' && req.post?
      req.ip
    end
  end

  ### Custom Throttle Response ###
  self.throttled_response = lambda do |env|
    [
      429, # status
      {'Content-Type' => 'application/json'}, # headers
      [{   # body
        status: 429,
        error: "Too many requests. Please try again later.",
        throttle_reset_in: (env['rack.attack.match_data'] || {})[:period]
      }.to_json]
    ]
  end
end