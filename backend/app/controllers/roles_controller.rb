class RolesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_role, only: %i[ show update destroy ]

  # GET /roles
  def index
      @roles = Role.all
      render json: {
        status: 200, 
        message: 'Roles found.',
        roles: @roles
    }, status: :ok 
  end

  # GET /roles/1
  def show
    render json: RoleSerializer.new(@role).serializable_hash[:data][:attributes]
  end

  # POST /roles
  def create
    @role = Role.new(role_params)

    if @role.save
      render json: {
        status: 200, 
        message: 'Role created.',
        role: @role
    }, status: :ok
    else
      render json: {errors: @role.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /roles/1
  def update
    if @role.update(role_params)
      render json: @role
    else
      render json: {errors: @role.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # DELETE /roles/1
  def destroy
    @role.destroy!
    render json: {
      status: 200,
      message: 'Role deleted.'
    }, status: :ok
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_role
      @role = Role.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def role_params
      params.expect(role: [ :name, :descripition, user_ids: [] ])
    end
end
