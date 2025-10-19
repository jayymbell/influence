class UsersController < ApplicationController
  before_action :authenticate_user!

  # GET /users
  def index
      @users = policy_scope(User)
      authorize User
      serialized_users = @users.map { |u| UserSerializer.new(u).serializable_hash[:data][:attributes] }
      render_success(data: { users: serialized_users }, message: 'Users found.')
  end

  def show
    @user = User.find(params[:id])
    authorize @user
    user_data = UserSerializer.new(@user).serializable_hash[:data][:attributes]
    render_success(data: { user: user_data }, message: 'User found.')
  end

  def update
    @user = User.find(params[:id])
    authorize @user
    if @user.update(user_params)
      user_data = UserSerializer.new(@user).serializable_hash[:data][:attributes]
      render_success(data: { user: user_data }, message: 'User updated.')
    else
      render_error(errors: @user.errors.full_messages, message: 'User update failed.')
    end
  end


  def destroy
    @user = User.find(params[:id])
    authorize @user
    if @user.discard
      render_success(message: 'User deactivated.')
    else
      render_error(errors: @user.errors.full_messages, message: 'User deactivation failed.')
    end
  end

  private

  def user_params
    params.expect(user: [ :discarded_at, role_ids: [] ])
  end
end