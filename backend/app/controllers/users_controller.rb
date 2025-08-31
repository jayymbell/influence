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

  def show
    @user = User.find(params[:id])
    render json: {
      status: 200, 
      message: 'User found.',
      user: @user
  }, status: :ok 
  end
end