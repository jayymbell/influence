# frozen_string_literal: true

class IssueClientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_issue

  # GET /issues/:issue_id/clients
  def index
    authorize @issue, :show?
    client_issues = @issue.client_issues.includes(:client, :shared_by)
    render_success(data: { clients: serialize_client_issues(client_issues) }, message: 'Clients found.')
  end

  # POST /issues/:issue_id/clients — share issue with another client
  def create
    authorize @issue, :share?
    client = Client.find(params[:client_id])

    link = @issue.client_issues.build(
      client:    client,
      shared_by: current_user,
      shared_at: Time.current
    )

    if link.save
      client_issues = @issue.client_issues.includes(:client, :shared_by)
      render_success(data: { clients: serialize_client_issues(client_issues) }, message: 'Issue shared with client.')
    else
      render_error(errors: link.errors.full_messages, message: 'Could not share issue.')
    end
  end

  # DELETE /issues/:issue_id/clients/:id — unshare (remove non-primary link)
  def destroy
    authorize @issue, :unshare?
    link = @issue.client_issues.find_by!(client_id: params[:id])

    link.destroy
    client_issues = @issue.client_issues.includes(:client, :shared_by)
    render_success(data: { clients: serialize_client_issues(client_issues) }, message: 'Issue unshared from client.')
  end

  private

  def set_issue
    @issue = Issue.find(params[:issue_id])
  end

  def serialize_client_issues(client_issues)
    client_issues.map do |ci|
      {
        id:           ci.client.id,
        display_name: ci.client.display_name,
        shared_at:    ci.shared_at,
        shared_by:    ci.shared_by ? { id: ci.shared_by.id, email: ci.shared_by.email } : nil
      }
    end
  end
end
