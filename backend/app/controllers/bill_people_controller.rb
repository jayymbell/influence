# frozen_string_literal: true

class BillPeopleController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bill

  # GET /bills/:bill_id/people
  def index
    authorize @bill, :show?
    render_success(data: { people: serialize_bill_people(ordered_bill_people(@bill)) }, message: 'People found.')
  end

  # POST /bills/:bill_id/people
  def create
    authorize @bill, :update?
    person = Person.find(params[:person_id])

    link = @bill.bill_people.build(person: person, added_by: current_user)

    if link.save
      render_success(
        data: { people: serialize_bill_people(ordered_bill_people(@bill.reload)) },
        message: 'Person added to bill.'
      )
    else
      render_error(errors: link.errors.full_messages, message: 'Could not add person to bill.')
    end
  end

  # DELETE /bills/:bill_id/people/:id
  def destroy
    authorize @bill, :update?
    link = @bill.bill_people.find_by!(person_id: params[:id])
    link.destroy
    render_success(
      data: { people: serialize_bill_people(ordered_bill_people(@bill.reload)) },
      message: 'Person removed from bill.'
    )
  end

  private

  def set_bill
    @bill = Bill.find(params[:bill_id])
  end

  def ordered_bill_people(bill)
    bill.bill_people.joins(:person).includes(:person).order('people.organization_name ASC, people.last_name ASC')
  end

  def serialize_bill_people(bill_people)
    bill_people.map do |bp|
      next nil unless bp.person

      {
        id:                bp.person.id,
        display_name:      bp.person.display_name,
        title:             bp.person.title,
        organization_name: bp.person.organization_name,
        email:             bp.person.email
      }
    end.compact
  end
end
