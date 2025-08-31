class Users::EventsController < ApplicationController
  respond_to :json
  before_action :authenticate_user!   # Devise helper

  def index

    if params[:user_id].blank?
      render json: { errors: ['user_id parameter is required'] }, status: :unprocessable_entity
      return
    end 

    @user = User.find(params[:user_id])
      @user_events = @user.events.order(time: :desc)
      render json: {
        status: 200, 
        message: 'Events found.',
        events: @user_events
    }, status: :ok 
  end

  def create
    ahoy.track params[:name], params[:properties] || {}
    render json: {
        status: { code: 200}
    }
  end
end
