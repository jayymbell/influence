class InvitationsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  # POST /invitations/accept
  def accept
    invitation = Invitation.find_by_raw_token(params[:token])

    unless invitation&.active?
      return render_error(
        errors: ['Invitation is invalid or has expired'],
        message: 'Invalid invitation.',
        status: :unprocessable_content
      )
    end

    user = User.new(
      email:                 invitation.email_snapshot,
      password:              params[:password],
      password_confirmation: params[:password_confirmation]
    )
    user.skip_confirmation!

    unless user.save
      return render_error(errors: user.errors.full_messages, message: 'Account creation failed.')
    end

    invitation.person.update!(user: user)
    invitation.update!(accepted_at: Time.current)

    # If the person is linked to a client, assign the client role
    if invitation.person.client_id.present?
      client_role = Role.find_by(name: 'client')
      user.roles << client_role if client_role && !user.roles.exists?(name: 'client')
    end

    token = generate_jwt_token(user)
    refresh_token = user.refresh_tokens.create!

    render_success(
      data: {
        token:         token,
        refresh_token: refresh_token.token,
        user:          UserSerializer.new(user).serializable_hash[:data][:attributes]
      },
      message: 'Account created. Welcome!'
    )
  end

  private

  def generate_jwt_token(user)
    encoder = Warden::JWTAuth::UserEncoder.new
    if encoder.method(:call).arity == 3
      encoder.call(user, :user, nil).first
    else
      headers_hash = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      encoder.call(user, :user, nil, headers_hash).first
    end
  end
end
