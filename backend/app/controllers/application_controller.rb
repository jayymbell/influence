class ApplicationController < ActionController::API
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized(exception)
    puts exception.inspect
    render json: {error: 'You do not have permission to access this'}, status: :forbidden
  end
end
