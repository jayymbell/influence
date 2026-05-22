# frozen_string_literal: true

class IssuesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_issue, only: %i[show update destroy close deactivate reactivate]

  # GET /issues
  def index
    @issues = policy_scope(Issue)
    authorize Issue

    @issues = @issues.where(status: params[:status]) if params[:status].present?
    if params[:client_id].present?
      cid = params[:client_id].to_i
      @issues = @issues.where(id: ClientIssue.where(client_id: cid).select(:issue_id))
    end

    if params[:query].present?
      q = "%#{params[:query].downcase}%"
      @issues = @issues.where('lower(title) LIKE ? OR lower(description) LIKE ?', q, q)
    end

    page     = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 25).to_i
    @issues  = @issues.includes(:client_issues, :issue_people)
                      .order(title: :asc)
                      .offset((page - 1) * per_page)
                      .limit(per_page)

    serialized = @issues.map { |i| issue_data(i) }
    render_success(data: { issues: serialized }, message: 'Issues found.')
  end

  # GET /issues/:id
  def show
    authorize @issue
    render_success(data: { issue: issue_data(@issue) }, message: 'Issue found.')
  end

  # POST /issues
  def create
    client_id = params.dig(:issue, :client_id)
    @issue = Issue.new(issue_params)
    @issue.created_by = current_user
    @issue.updated_by = current_user
    authorize @issue

    if @issue.save
      @issue.client_issues.create!(client_id: client_id, shared_by: current_user, shared_at: Time.current) if client_id.present?
      render_success(data: { issue: issue_data(@issue) }, message: 'Issue created.', status: :created)
    else
      render_error(errors: @issue.errors.full_messages, message: 'Issue creation failed.')
    end
  end

  # PATCH /issues/:id
  def update
    authorize @issue
    @issue.updated_by = current_user

    if @issue.update(issue_params)
      render_success(data: { issue: issue_data(@issue) }, message: 'Issue updated.')
    else
      render_error(errors: @issue.errors.full_messages, message: 'Issue update failed.')
    end
  end

  # DELETE /issues/:id — sets to inactive
  def destroy
    authorize @issue
    @issue.update!(status: :inactive, updated_by: current_user)
    render_success(message: 'Issue deactivated.')
  end

  # POST /issues/:id/close
  def close
    authorize @issue
    @issue.update!(status: :closed, closed_at: Time.current, closed_by: current_user, updated_by: current_user)
    render_success(data: { issue: issue_data(@issue) }, message: 'Issue closed.')
  end

  # POST /issues/:id/deactivate
  def deactivate
    authorize @issue
    @issue.update!(status: :inactive, updated_by: current_user)
    render_success(data: { issue: issue_data(@issue) }, message: 'Issue deactivated.')
  end

  # POST /issues/:id/reactivate
  def reactivate
    authorize @issue
    @issue.update!(status: :active, closed_at: nil, closed_by: nil, updated_by: current_user)
    render_success(data: { issue: issue_data(@issue) }, message: 'Issue reactivated.')
  end

  private

  def set_issue
    @issue = Issue.find(params[:id])
  end

  def issue_data(issue)
    IssueSerializer.new(issue).serializable_hash[:data][:attributes]
  end

  def issue_params
    params.expect(issue: [:title, :description, :notes, :status, { tags: [] }])
  end
end
