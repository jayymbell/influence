class PeopleController < ApplicationController
  before_action :authenticate_user!
  before_action :set_person, only: %i[show update destroy]

  # GET /people
  def index
    @people = policy_scope(Person)
    authorize Person

    @people = @people.where("lower(display_name) LIKE ?", "%#{params[:query].downcase}%") if params[:query].present?

    page     = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 25).to_i
    @people  = @people.order(updated_at: :desc).offset((page - 1) * per_page).limit(per_page)

    serialized = @people.map { |p| PersonSerializer.new(p).serializable_hash[:data][:attributes] }
    render_success(data: { people: serialized }, message: 'People found.')
  end

  # GET /people/:id
  def show
    authorize @person
    render_success(data: { person: person_data(@person) }, message: 'Person found.')
  end

  # POST /people
  def create
    @person = Person.new(person_params)
    @person.created_by = current_user
    @person.updated_by = current_user
    authorize @person

    if @person.save
      render_success(data: { person: person_data(@person) }, message: 'Person created.', status: :created)
    else
      render_error(errors: @person.errors.full_messages, message: 'Person creation failed.')
    end
  end

  # PATCH /people/:id
  def update
    authorize @person
    @person.updated_by = current_user

    if @person.update(person_params)
      render_success(data: { person: person_data(@person) }, message: 'Person updated.')
    else
      render_error(errors: @person.errors.full_messages, message: 'Person update failed.')
    end
  end

  # DELETE /people/:id
  def destroy
    authorize @person
    @person.update!(deactivated_at: Time.current, deactivated_by: current_user)
    @person.discard
    render_success(message: 'Person deactivated.')
  end

  private

  def set_person
    @person = Person.find(params[:id])
  end

  def person_data(person)
    PersonSerializer.new(person).serializable_hash[:data][:attributes]
  end

  def person_params
    params.expect(person: [
      :first_name,
      :last_name,
      :display_name,
      :email,
      :phone,
      :title,
      :organization_name,
      :notes,
      :user_id
    ])
  end
end
