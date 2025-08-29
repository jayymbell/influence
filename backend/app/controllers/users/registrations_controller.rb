class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  def update
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
      render json: {
        status: 422,
        message: 'Account update failed.',
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
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
      render json: {
        status: 422,
        message: 'Sign up failed.',
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :current_password)
  end
end
