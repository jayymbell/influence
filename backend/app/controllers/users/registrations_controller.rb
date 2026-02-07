class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  def update
    authenticate_user!   # Devise helper
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    resource_updated = update_resource(resource, user_params)
    yield resource if block_given?
    if resource_updated
      render json: {
        status: 200,
        message: I18n.t('devise.registrations.updated'),
        user: UserSerializer.new(resource).serializable_hash[:data][:attributes]
      }
    else
  render_error(errors: resource.errors.full_messages, message: 'Account update failed.', status: :unprocessable_content)
    end
  end

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?

      render json: {
        status: 200,
        message: I18n.t('devise.registrations.signed_up_but_unconfirmed')
      }
    else
      render_error(errors: resource.errors.full_messages, message: 'Sign up failed.', status: :unprocessable_content)
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :current_password)
  end
end
