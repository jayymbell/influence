class Users::RefreshTokensController < ApplicationController
  respond_to :json

  def create
    token = params[:refresh_token].to_s.strip
    @refresh_token = RefreshToken.find_by(token: token)

    unless @refresh_token&.active?
      render_error(errors: ['Invalid or expired refresh token'], message: 'Invalid or expired refresh token', status: :unauthorized)
      return
    end

    # Revoke the current refresh token
    @refresh_token.revoke!

    # Create a new refresh token
    new_refresh_token = @refresh_token.user.refresh_tokens.create!

    # Return new access token and refresh token
    render json: {
      status: 200,
      message: 'Token refreshed successfully',
      data: {
        token: generate_jwt_token(@refresh_token.user),
        refresh_token: new_refresh_token.token
      }
    }
  end

  private

  def generate_jwt_token(user)
    encoder = Warden::JWTAuth::UserEncoder.new
    # Different versions of warden-jwt_auth expect different arities for `call`.
    # Call with 3 args if that's the signature, otherwise pass headers as the 4th arg.
    if encoder.method(:call).arity == 3
      encoder.call(user, :user, nil).first
    else
      headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      encoder.call(user, :user, nil, headers).first
    end
  end
end