# frozen_string_literal: true

class BillIssuesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bill

  # GET /bills/:bill_id/issues
  def index
    authorize @bill, :show?
    issues = @bill.bill_issues.includes(:issue).map { |bi| bi.issue }.compact
    render_success(data: { issues: issues.map { |i| serialize_issue(i) } }, message: 'Issues found.')
  end

  # POST /bills/:bill_id/issues
  def create
    authorize @bill, :update?
    issue = Issue.find(params[:issue_id])

    link = @bill.bill_issues.build(issue: issue, added_by: current_user, added_at: Time.current)

    if link.save
      issues = @bill.reload.bill_issues.includes(:issue).map { |bi| bi.issue }.compact
      render_success(data: { issues: issues.map { |i| serialize_issue(i) } }, message: 'Issue linked to bill.')
    else
      render_error(errors: link.errors.full_messages, message: 'Could not link issue to bill.')
    end
  end

  # DELETE /bills/:bill_id/issues/:id
  def destroy
    authorize @bill, :update?
    link = @bill.bill_issues.find_by!(issue_id: params[:id])
    link.destroy
    issues = @bill.reload.bill_issues.includes(:issue).map { |bi| bi.issue }.compact
    render_success(data: { issues: issues.map { |i| serialize_issue(i) } }, message: 'Issue unlinked from bill.')
  end

  private

  def set_bill
    @bill = Bill.find(params[:bill_id])
  end

  def serialize_issue(issue)
    {
      id:     issue.id,
      title:  issue.title,
      status: issue.status
    }
  end
end
