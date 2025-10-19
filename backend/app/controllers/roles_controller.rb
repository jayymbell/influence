class RolesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_role, only: %i[ show update destroy ]

  # GET /roles
  def index
      @roles = Role.all
      authorize @roles
      serialized_roles = @roles.map { |r| RoleSerializer.new(r).serializable_hash[:data][:attributes] }
      render json: {
        status: 200, 
        message: 'Roles found.',
        roles: serialized_roles
    }, status: :ok 
  end

  # GET /roles/1
  def show
    authorize @role
    render json: RoleSerializer.new(@role).serializable_hash[:data][:attributes]
  end

  # POST /roles
  def create
    @role = Role.new(role_params)
    authorize @role
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
    authorize @role
    if @role.update(role_params)
      render json: @role
    else
      render json: {errors: @role.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # DELETE /roles/1
  def destroy
    authorize @role
    @role.destroy!
    render json: {
      status: 200,
      message: 'Role deleted.'
    }, status: :ok
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_role
      @role = Role.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def role_params
      params.expect(role: [ :name, :description, user_ids: [] ])
    end
end
