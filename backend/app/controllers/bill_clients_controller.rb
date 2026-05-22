# frozen_string_literal: true

class BillClientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bill

  # GET /bills/:bill_id/clients
  def index
    authorize @bill, :show?
    render_success(data: { clients: serialize_bill_clients(@bill.bill_clients.includes(:client, :shared_by)) }, message: 'Clients found.')
  end

  # POST /bills/:bill_id/clients
  def create
    authorize @bill, :update?
    client = Client.find(params[:client_id])

    link = @bill.bill_clients.build(
      client:    client,
      shared_by: current_user,
      shared_at: Time.current
    )

    if link.save
      render_success(data: { clients: serialize_bill_clients(@bill.reload.bill_clients.includes(:client, :shared_by)) }, message: 'Client linked to bill.')
    else
      render_error(errors: link.errors.full_messages, message: 'Could not link client to bill.')
    end
  end

  # DELETE /bills/:bill_id/clients/:id
  def destroy
    authorize @bill, :update?
    link = @bill.bill_clients.find_by!(client_id: params[:id])
    link.destroy
    render_success(data: { clients: serialize_bill_clients(@bill.reload.bill_clients.includes(:client, :shared_by)) }, message: 'Client unlinked from bill.')
  end

  private

  def set_bill
    @bill = Bill.find(params[:bill_id])
  end

  def serialize_bill_clients(bill_clients)
    bill_clients.map do |bc|
      {
        id:           bc.client.id,
        display_name: bc.client.display_name,
        shared_at:    bc.shared_at,
        shared_by:    bc.shared_by ? { id: bc.shared_by.id, email: bc.shared_by.email } : nil
      }
    end
  end
end
