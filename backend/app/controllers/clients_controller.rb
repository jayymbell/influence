# frozen_string_literal: true

class ClientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_client, only: %i[show update destroy reactivate]

  # GET /clients
  def index
    @clients = policy_scope(Client)
    authorize Client

    if params[:discarded] == 'true'
      @clients = @clients.discarded
    else
      @clients = @clients.kept
    end

    @clients = @clients.where('lower(legal_name) LIKE ? OR lower(display_name) LIKE ?',
                              "%#{params[:query].to_s.downcase}%",
                              "%#{params[:query].to_s.downcase}%") if params[:query].present?

    page     = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 25).to_i
    @clients = @clients.order(updated_at: :desc).offset((page - 1) * per_page).limit(per_page)

    serialized = @clients.map { |c| ClientSerializer.new(c).serializable_hash[:data][:attributes] }
    render_success(data: { clients: serialized }, message: 'Clients found.')
  end

  # GET /clients/similar?query=...
  # Returns active clients whose name is similar to the query (trigram similarity >= 0.15),
  # excluding exact matches so the caller can surface duplicate warnings.
  def similar
    authorize Client, :index?

    query = params[:query].to_s.strip
    return render_success(data: { clients: [] }, message: 'No query.') if query.length < 2

    order_sql = Arel.sql(
      Client.sanitize_sql_array([
        'GREATEST(similarity(lower(legal_name), lower(?)), similarity(lower(display_name), lower(?))) DESC',
        query, query
      ])
    )

    @clients = Client.kept
                     .where(
                       'similarity(lower(legal_name), lower(:q)) >= 0.15 OR similarity(lower(display_name), lower(:q)) >= 0.15',
                       q: query
                     )
                     .order(order_sql)
                     .limit(5)

    serialized = @clients.map { |c| ClientSerializer.new(c).serializable_hash[:data][:attributes] }
    render_success(data: { clients: serialized }, message: 'Similar clients found.')
  end

  # GET /clients/:id
  def show
    authorize @client
    render_success(data: { client: client_data(@client) }, message: 'Client found.')
  end

  # POST /clients
  def create
    @client = Client.new(client_params)
    @client.created_by = current_user
    @client.updated_by = current_user
    authorize @client

    if @client.save
      render_success(data: { client: client_data(@client) }, message: 'Client created.', status: :created)
    else
      render_error(errors: @client.errors.full_messages, message: 'Client creation failed.')
    end
  end

  # PATCH /clients/:id
  def update
    authorize @client
    @client.updated_by = current_user

    if @client.update(client_params)
      render_success(data: { client: client_data(@client) }, message: 'Client updated.')
    else
      render_error(errors: @client.errors.full_messages, message: 'Client update failed.')
    end
  end

  # DELETE /clients/:id — soft deactivate only
  def destroy
    authorize @client
    @client.update!(deactivated_at: Time.current, deactivated_by: current_user)
    @client.discard
    render_success(message: 'Client deactivated.')
  end

  # POST /clients/:id/reactivate
  def reactivate
    authorize @client
    @client.undiscard
    @client.update!(deactivated_at: nil, deactivated_by: nil, updated_by: current_user)
    render_success(data: { client: client_data(@client) }, message: 'Client reactivated.')
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_data(client)
    ClientSerializer.new(client).serializable_hash[:data][:attributes]
  end

  def client_params
    params.expect(client: [:legal_name, :display_name])
  end
end
