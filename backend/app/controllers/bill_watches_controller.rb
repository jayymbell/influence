# frozen_string_literal: true

class BillWatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bill

  # POST /bills/:bill_id/watch
  def create
    authorize @bill, :watch?

    watch = BillWatch.find_or_initialize_by(user: current_user, bill: @bill)

    if watch.persisted?
      return render_success(data: { watched: true }, message: "Already watching this bill.")
    end

    if watch.save
      render_success(data: { watched: true }, message: "Now watching this bill.", status: :created)
    else
      render_error(errors: watch.errors.full_messages, message: "Could not watch bill.")
    end
  end

  # DELETE /bills/:bill_id/watch
  def destroy
    authorize @bill, :watch?

    watch = BillWatch.find_by(user: current_user, bill: @bill)

    if watch&.destroy
      render_success(data: { watched: false }, message: "No longer watching this bill.")
    else
      render_error(errors: ["You are not watching this bill."], message: "Not watching.", status: :not_found)
    end
  end

  private

  def set_bill
    @bill = Bill.find(params[:id])
  end
end
