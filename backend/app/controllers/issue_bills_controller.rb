# frozen_string_literal: true

class IssueBillsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_issue

  # GET /issues/:issue_id/bills
  def index
    authorize @issue, :show?
    bills = @issue.bill_issues.includes(:bill).map { |bi| bi.bill }.compact
    render_success(data: { bills: bills.map { |b| serialize_bill(b) } }, message: 'Bills found.')
  end

  # POST /issues/:issue_id/bills
  def create
    authorize @issue, :update?
    bill = Bill.find(params[:bill_id])

    link = @issue.bill_issues.build(bill: bill, added_by: current_user, added_at: Time.current)

    if link.save
      bills = @issue.reload.bill_issues.includes(:bill).map { |bi| bi.bill }.compact
      render_success(data: { bills: bills.map { |b| serialize_bill(b) } }, message: 'Bill linked to issue.')
    else
      render_error(errors: link.errors.full_messages, message: 'Could not link bill to issue.')
    end
  end

  # DELETE /issues/:issue_id/bills/:id
  def destroy
    authorize @issue, :update?
    link = @issue.bill_issues.find_by!(bill_id: params[:id])
    link.destroy
    bills = @issue.reload.bill_issues.includes(:bill).map { |bi| bi.bill }.compact
    render_success(data: { bills: bills.map { |b| serialize_bill(b) } }, message: 'Bill unlinked from issue.')
  end

  private

  def set_issue
    @issue = Issue.find(params[:issue_id])
  end

  def serialize_bill(bill)
    {
      id:          bill.id,
      bill_number: bill.bill_number,
      title:       bill.title,
      status:      bill.status,
      chamber:     bill.chamber
    }
  end
end
