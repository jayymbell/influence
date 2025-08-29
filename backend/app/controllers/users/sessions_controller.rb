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
    if request.headers['Authorization'].present?
      jwt_payload = JWT.decode(request.headers['Authorization'].split.last, Rails.application.credentials.jwt_secret_key!).first
      current_user = User.find(jwt_payload['sub'])
    end

    puts "CURRENT USER: #{current_user.inspect}"

    if current_user
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