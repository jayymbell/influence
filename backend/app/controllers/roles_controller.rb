class RolesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_role, only: %i[ show update destroy ]

  # GET /roles
  def index
      @roles = policy_scope(Role)
      authorize Role
      serialized_roles = @roles.map { |r| RoleSerializer.new(r).serializable_hash[:data][:attributes] }
      render_success(data: { roles: serialized_roles }, message: 'Roles found.')
  end

  # GET /roles/1
  def show
    authorize @role
    role_data = RoleSerializer.new(@role).serializable_hash[:data][:attributes]
    render_success(data: { role: role_data }, message: 'Role found.')
  end

  # POST /roles
  def create
    @role = Role.new(role_params)
    authorize @role
    if @role.save
      role_data = RoleSerializer.new(@role).serializable_hash[:data][:attributes]
      render_success(data: { role: role_data }, message: 'Role created.')
    else
      render_error(errors: @role.errors.full_messages, message: 'Role creation failed.')
    end
  end

  # PATCH/PUT /roles/1
  def update
    authorize @role
    if @role.update(role_params)
      role_data = RoleSerializer.new(@role).serializable_hash[:data][:attributes]
      render_success(data: { role: role_data }, message: 'Role updated.')
    else
      render_error(errors: @role.errors.full_messages, message: 'Role update failed.')
    end
  end

  # DELETE /roles/1
  def destroy
    authorize @role
    @role.destroy!
    render_success(message: 'Role deleted.')
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
