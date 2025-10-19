class Users::EventsController < ApplicationController
  respond_to :json
  before_action :authenticate_user!   # Devise helper

  def index

    if params[:user_id].blank?
      render json: { errors: ['user_id parameter is required'] }, status: :unprocessable_entity
      return
    end 

    @user = User.find(params[:user_id])
      unless current_user == @user || current_user.admin?
        render json: { error: 'You do not have permission to access this' }, status: :forbidden
        return
      end

      @user_events = @user.events.order(time: :desc)
      render json: {
        status: 200, 
        message: 'Events found.',
        events: @user_events
    }, status: :ok 
  end

  def create
    name = params[:name].to_s.strip
    properties = params[:properties].is_a?(Hash) ? params[:properties] : {}

    if name.empty?
      render json: { errors: ['name is required'] }, status: :unprocessable_entity
      return
    end

    # Basic size guardrails for properties payload
    if properties.to_json.bytesize > 10_000
      render json: { errors: ['properties payload too large'] }, status: :unprocessable_entity
      return
    end

    ahoy.track name, properties
    render json: { status: { code: 200 } }
  end
end
