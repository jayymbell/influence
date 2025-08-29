class Users::PasswordsController < Devise::PasswordsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if action_name == 'create'
      render json: {
        status: { code: 200, message: I18n.t('devise.passwords.send_paranoid_instructions') }
      }
    elsif resource.errors.blank?
      render json: {
        status: { code: 200, message: I18n.t('devise.passwords.updated_not_active') }
      }
    else
      render json: {
        status: { message: 'Password reset failed.' },
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
end