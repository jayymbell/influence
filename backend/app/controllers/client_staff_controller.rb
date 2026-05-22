# frozen_string_literal: true

class ClientStaffController < ApplicationController
  before_action :authenticate_user!
  before_action :set_client

  # GET /clients/:client_id/staff
  def index
    authorize @client, :show?
    staff = @client.staff.includes(:person).kept
    render_success(data: { staff: serialize_staff(staff) }, message: 'Staff found.')
  end

  # GET /clients/:client_id/staff/available
  def available
    authorize @client, :manage_staff?
    assigned_ids = @client.client_staff.pluck(:user_id)
    users = User.kept
                .joins(:person)
                .joins(user_roles: :role)
                .where(roles: { name: %w[admin staff] })
                .where.not(id: assigned_ids)
                .includes(:person)
                .distinct
    render_success(data: { users: serialize_staff(users) }, message: 'Available staff found.')
  end

  # POST /clients/:client_id/staff
  def create
    authorize @client, :manage_staff?
    user = User.find(params[:user_id])
    assignment = @client.client_staff.build(user: user)
    if assignment.save
      render_success(data: { staff: serialize_staff(@client.staff.includes(:person).kept) }, message: 'Staff added.')
    else
      render_error(errors: assignment.errors.full_messages, message: 'Could not add staff.')
    end
  end

  # DELETE /clients/:client_id/staff/:id
  def destroy
    authorize @client, :manage_staff?
    assignment = @client.client_staff.find_by!(user_id: params[:id])
    assignment.destroy
    render_success(data: { staff: serialize_staff(@client.staff.includes(:person).kept) }, message: 'Staff removed.')
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  end

  def serialize_staff(users)
    users.map do |u|
      {
        id: u.id,
        email: u.email,
        display_name: u.person&.display_name
      }
    end
  end
end
