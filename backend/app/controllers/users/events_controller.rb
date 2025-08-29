class Users::EventsController < ApplicationController
  respond_to :json
  before_action :authenticate_user!   # Devise helper

  def create
    ahoy.track params[:name], params[:properties] || {}
    render json: {
        status: { code: 200}
    }
  end
end
