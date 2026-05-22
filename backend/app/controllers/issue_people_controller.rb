# frozen_string_literal: true

class IssuePeopleController < ApplicationController
  before_action :authenticate_user!
  before_action :set_issue

  # GET /issues/:issue_id/people
  def index
    authorize @issue, :show?
    render_success(data: { people: serialize_issue_people(ordered_issue_people(@issue)) }, message: 'People found.')
  end

  # POST /issues/:issue_id/people
  def create
    authorize @issue, :update?
    person = Person.find(params[:person_id])

    link = @issue.issue_people.build(person: person, added_by: current_user)

    if link.save
      render_success(
        data: { people: serialize_issue_people(ordered_issue_people(@issue)) },
        message: 'Person added to issue.'
      )
    else
      render_error(errors: link.errors.full_messages, message: 'Could not add person to issue.')
    end
  end

  # DELETE /issues/:issue_id/people/:id
  def destroy
    authorize @issue, :update?
    link = @issue.issue_people.find_by!(person_id: params[:id])
    link.destroy
    render_success(
      data: { people: serialize_issue_people(ordered_issue_people(@issue)) },
      message: 'Person removed from issue.'
    )
  end

  private

  def set_issue
    @issue = Issue.find(params[:issue_id])
  end

  def ordered_issue_people(issue)
    issue.issue_people.joins(:person).includes(:person).order('people.last_name ASC')
  end

  def serialize_issue_people(issue_people)
    issue_people.map do |ip|
      next nil unless ip.person

      {
        id:                ip.person.id,
        display_name:      ip.person.display_name,
        title:             ip.person.title,
        organization_name: ip.person.organization_name,
        email:             ip.person.email
      }
    end.compact
  end
end
