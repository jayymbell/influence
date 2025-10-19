class Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opt= {})
    if resource.persisted?
      @token = request.env['warden-jwt_auth.token']
      headers['Authorization'] = @token

      render json: {
          status: 200, 
          message: I18n.t('devise.sessions.signed_in'),
          token: @token,
          user: UserSerializer.new(resource).serializable_hash[:data][:attributes]
      }, status: :ok
    else
      render json: {
          status: 401,
          message: I18n.t('devise.failure.invalid', authentication_keys: 'token')
      }, status: :unauthorized
    end
  end

  def respond_to_on_destroy
    authorization_header = request.headers['Authorization'].to_s
    if authorization_header.present?
      render json: {
        status: 200,
        message: I18n.t('devise.sessions.signed_out')
      }, status: :ok
    else
      render json: {
        status: 401,
        message: I18n.t('devise.errors.messages.not_found')
      }, status: :unauthorized
    end
  end
end