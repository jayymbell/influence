class Users::EventsController < ApplicationController
  respond_to :json
  before_action :authenticate_user!   # Devise helper

  def index
    if params[:user_id].blank?
      render_error(errors: ['user_id parameter is required'], message: 'Missing required parameter.')
      return
    end 

    @user = User.find(params[:user_id])
    unless current_user == @user || current_user.admin?
      render json: { error: 'You do not have permission to access this' }, status: :forbidden
      return
    end

    @user_events = @user.events.order(time: :desc)
    render_success(data: { events: @user_events }, message: 'Events found.')
  end

  def create
    name = params[:name].to_s.strip
    properties = params[:properties].is_a?(Hash) ? params[:properties] : {}

    if name.empty?
      render_error(errors: ['name is required'], message: 'Event name is required.')
      return
    end

    # Basic size guardrails for properties payload
    if properties.to_json.bytesize > 10_000
      render_error(errors: ['properties payload too large'], message: 'Event properties too large.')
      return
    end

    ahoy.track name, properties
    render_success(message: 'Event tracked.')
  end
end
