class UsersController < ApplicationController
  before_action :authenticate_user!

  # GET /users
  def index
      @users = User.all
      authorize @users
      render json: {
        status: 200, 
        message: 'Users found.',
        users: @users
    }, status: :ok 
  end

  def show
    @user = User.find(params[:id])
    authorize @user
    render json: {
      status: 200, 
      message: 'User found.',
      user: UserSerializer.new(@user).serializable_hash[:data][:attributes]
  }, status: :ok 
  end

  def update
    @user = User.find(params[:id])
    authorize @user
    if @user.update(user_params)
      render json: UserSerializer.new(@user).serializable_hash[:data][:attributes]
    else
      render json: {errors: @role.errors.full_messages}, status: :unprocessable_entity
    end
  end


  def destroy
    @user = User.find(params[:id])
    authorize @user
    if @user.discard
      render json: {
        status: 200,
        message: 'User deactivated.'
      }, status: :ok
    else
      render json: {
        status: 422,
        message: 'User deactivation failed.',
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: [ :discarded_at, role_ids: [] ])
  end
end