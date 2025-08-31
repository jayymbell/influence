class UsersController < ApplicationController
  before_action :authenticate_user!

  # GET /users
  def index
      @users = User.all
      render json: {
        status: 200, 
        message: 'Users found.',
        users: @users
    }, status: :ok 
  end
end