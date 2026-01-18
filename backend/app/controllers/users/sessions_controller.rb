class Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opt= {})
    if resource.persisted?
      @token = request.env['warden-jwt_auth.token']
      headers['Authorization'] = "Bearer #{@token}"

      # Create a refresh token
      refresh_token = resource.refresh_tokens.create!

      render json: {
        status: { code: 200, message: 'Logged in successfully.' },
        data: UserSerializer.new(resource).serializable_hash[:data][:attributes],
        token: @token,
        refresh_token: refresh_token.token
      }
    else
      render_error(errors: I18n.t('devise.failure.invalid', authentication_keys: 'token'), message: I18n.t('devise.failure.invalid', authentication_keys: 'token'), status: :unauthorized)
    end
  end

  def respond_to_on_destroy
    authorization_header = request.headers['Authorization'].to_s
    if authorization_header.present?
      # Revoke all refresh tokens for the user on logout
      current_user&.refresh_tokens&.update_all(revoked_at: Time.current, revocation_reason: 'logout')
      
      render json: {
          status: 200,
          message: 'Logged out successfully.'
      }
    else
      render_error(errors: ['Token not found.'], message: 'Token not found.', status: :unauthorized)
    end
  end
end