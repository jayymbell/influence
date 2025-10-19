class JwtClaimsService
  def self.call(user, request)
    {
      iat: Time.current.to_i,
      jti: SecureRandom.uuid,
      iss: 'rvp-template-basic',
      sub: user.id,
      ip: request.remote_ip,
      ua: request.user_agent
    }
  end
end