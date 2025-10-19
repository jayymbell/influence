class ApplicationController < ActionController::API
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized(exception)
    puts exception.inspect
    render json: {error: 'You do not have permission to access this'}, status: :forbidden
  end

  # Standardized JSON response format
  def render_success(data: nil, message: 'Success', status: :ok)
    response = { status: Rack::Utils.status_code(status), message: message }
    response[:data] = data if data.present?
    render json: response, status: status
  end

  def render_error(errors:, message: 'Error', status: :unprocessable_entity)
    render json: {
      status: Rack::Utils.status_code(status),
      message: message,
      errors: errors.is_a?(Array) ? errors : [errors]
    }, status: status
  end
end
