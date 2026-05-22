# frozen_string_literal: true

class BillsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bill, only: %i[show update destroy link_external refresh]

  rescue_from BillImportService::ExternalError do |e|
    render_error(errors: [ e.message ], message: "External service error.", status: :bad_gateway)
  end

  # GET /bills
  def index
    @bills = policy_scope(Bill)
    authorize Bill

    @bills = @bills.where(status: params[:status])       if params[:status].present?
    @bills = @bills.where(chamber: params[:chamber])     if params[:chamber].present?
    @bills = @bills.where(session_year: params[:session_year]) if params[:session_year].present?

    if params[:client_id].present?
      cid = params[:client_id].to_i
      @bills = @bills.where(id: BillClient.where(client_id: cid).select(:bill_id))
    end

    if params[:query].present?
      q = "%#{params[:query].downcase}%"
      @bills = @bills.where(
        'lower(title) LIKE ? OR lower(bill_number) LIKE ? OR lower(description) LIKE ?',
        q, q, q
      )
    end

    page     = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 25).to_i
    order_sql = Arel.sql(
      "COALESCE(REGEXP_REPLACE(bill_number, '[^0-9]', '', 'g'), '')::bigint ASC, bill_number ASC"
    )
    @bills   = @bills.includes(:bill_issues, :bill_clients, :bill_people)
                     .order(order_sql)
                     .offset((page - 1) * per_page)
                     .limit(per_page)

    serialized = @bills.map { |b| bill_data(b) }
    render_success(data: { bills: serialized }, message: 'Bills found.')
  end

  # GET /bills/:id
  def show
    authorize @bill
    render_success(data: { bill: bill_data(@bill) }, message: 'Bill found.')
  end

  # POST /bills
  def create
    @bill = Bill.new(bill_params)
    @bill.created_by = current_user
    @bill.updated_by = current_user
    authorize @bill

    if @bill.save
      render_success(data: { bill: bill_data(@bill) }, message: 'Bill created.', status: :created)
    else
      render_error(errors: @bill.errors.full_messages, message: 'Bill creation failed.')
    end
  end

  # PATCH /bills/:id
  def update
    authorize @bill
    @bill.updated_by = current_user

    if @bill.update(bill_params)
      render_success(data: { bill: bill_data(@bill) }, message: 'Bill updated.')
    else
      render_error(errors: @bill.errors.full_messages, message: 'Bill update failed.')
    end
  end

  # DELETE /bills/:id — sets status to failed (soft deactivation)
  def destroy
    authorize @bill
    @bill.update!(status: :failed, updated_by: current_user)
    render_success(message: 'Bill deactivated.')
  end

  # GET /bills/search?q=...
  def search
    authorize Bill, :search?
    query    = params[:q].to_s.strip
    page     = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 20).to_i

    if query.blank?
      return render_error(errors: [ "q parameter is required" ], message: "Search query missing.")
    end

    result = BillImportService.search(query: query, page: page, per_page: per_page)
    render_success(data: result, message: "Search results found.")
  end

  # POST /bills/import
  def import
    authorize Bill, :import?
    external_id = params[:external_id].to_s.strip

    if external_id.blank?
      return render_error(errors: [ "external_id is required" ], message: "Import failed.")
    end

    bill, status_sym = BillImportService.import(external_id: external_id, created_by: current_user)
    http_status = status_sym == :created ? :created : :ok
    render_success(data: { bill: bill_data(bill) }, message: "Bill #{status_sym == :created ? 'imported' : 'already exists'}.", status: http_status)
  end

  # PATCH /bills/:id/link_external
  def link_external
    authorize @bill, :link_external?
    external_id = params[:external_id].to_s.strip

    if external_id.blank?
      return render_error(errors: [ "external_id is required" ], message: "Link failed.")
    end

    bill = BillImportService.link(bill: @bill, external_id: external_id)
    render_success(data: { bill: bill_data(bill) }, message: "Bill linked to external record.")
  rescue BillImportService::ExternalError => e
    render_error(errors: [ e.message ], message: "Link failed.", status: :unprocessable_content)
  end

  # POST /bills/:id/refresh
  def refresh
    authorize @bill, :refresh?

    if @bill.external_id.blank?
      return render_error(errors: [ "Bill is not linked to an external record" ], message: "Refresh failed.")
    end

    bill = BillImportService.refresh(bill: @bill)
    render_success(data: { bill: bill_data(bill) }, message: "Bill refreshed.")
  end

  private

  def set_bill
    @bill = Bill.find(params[:id])
  end

  def bill_data(bill)
    BillSerializer.new(bill).serializable_hash[:data][:attributes]
  end

  def bill_params
    params.expect(bill: [
      :bill_number, :chamber, :session_year, :title, :description,
      :notes, :status, :companion_bill_id, { tags: [] }
    ])
  end
end
