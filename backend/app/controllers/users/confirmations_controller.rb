class Users::ConfirmationsController < Devise::ConfirmationsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if resource.errors.blank?

      render json: {
        status: { code: 200, message: 'Email confirmed.' }
      }
    else
      render json: {
        status: { message: 'Confirmation failed.' },
        errors: resource.errors.collect(&:type).map{ |error| error.to_s.humanize }
      }, status: :unprocessable_entity
    end
  end
end
