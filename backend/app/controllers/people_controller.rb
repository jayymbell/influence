class PeopleController < ApplicationController
  before_action :authenticate_user!
  before_action :set_person, only: %i[show update destroy invite reactivate revoke_invitation add_client assign_staff]

  # GET /people
  def index
    @people = policy_scope(Person)
    authorize Person

    if params[:discarded] == 'true'
      @people = @people.discarded
    else
      @people = @people.kept
    end

    @people = @people.where("lower(display_name) LIKE ?", "%#{params[:query].downcase}%") if params[:query].present?
    @people = @people.where(client_id: params[:client_id]) if params[:client_id].present?

    page     = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 25).to_i
    @people  = @people.order(last_name: :asc).offset((page - 1) * per_page).limit(per_page)

    serialized = @people.includes(:active_invitation).map { |p| PersonSerializer.new(p).serializable_hash[:data][:attributes] }
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

    # Regular users can only create a person linked to themselves
    unless current_user.admin? || current_user.staff?
      @person.user  = current_user
      @person.email = current_user.email
    end

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

  # POST /people/:id/reactivate
  def reactivate
    authorize @person
    @person.undiscard
    @person.update!(deactivated_at: nil, deactivated_by: nil, updated_by: current_user)
    render_success(data: { person: person_data(@person) }, message: 'Person reactivated.')
  end

  # POST /people/:id/invite
  def invite
    authorize @person, :invite?

    unless @person.email.present?
      return render_error(errors: ['Person has no email address'], message: 'Cannot send invitation.')
    end

    if @person.user_id.present?
      return render_error(errors: ['Person already has a user account'], message: 'Cannot send invitation.')
    end

    invite_as = @person.client_id.present? ? 'client' : 'staff'
    raw_token = Invitation.generate_for(@person, invited_by: current_user, invite_as: invite_as)
    InvitationsMailer.invite(@person.active_invitation, raw_token).deliver_later
    render_success(message: 'Invitation sent.')
  end

  # POST /people/:id/add_client
  def add_client
    authorize @person, :add_client?

    org_name = params[:organization_name].presence || @person.organization_name
    unless org_name.present?
      return render_error(errors: ['Person has no organization name'], message: 'Cannot add as client.')
    end

    # Find existing client by case-insensitive legal or display name match
    client = Client.find_by('lower(legal_name) = lower(?) OR lower(display_name) = lower(?)', org_name, org_name)

    # Create if not found
    unless client
      client = Client.new(legal_name: org_name, display_name: org_name,
                          created_by: current_user, updated_by: current_user)
      unless client.save
        return render_error(errors: client.errors.full_messages, message: 'Client creation failed.')
      end
    end

    @person.update!(client: client, organization_name: client.display_name, updated_by: current_user)

    client_role = Role.find_by!(name: 'client')

    if @person.user.present?
      @person.user.roles << client_role unless @person.user.roles.exists?(name: 'client')
    end

    render_success(data: { person: person_data(@person) }, message: 'Person added as client contact.')
  end

  # POST /people/:id/assign_staff
  def assign_staff
    authorize @person, :assign_staff?

    unless @person.user.present?
      return render_error(errors: ['Person has no user account'], message: 'Cannot assign role.')
    end

    staff_role = Role.find_by!(name: 'staff')
    if @person.user.roles.exists?(name: 'staff')
      return render_error(errors: ['Person already has the staff role'], message: 'Role already assigned.')
    end

    @person.user.roles << staff_role
    render_success(data: { person: person_data(@person) }, message: 'Staff role assigned.')
  end

  # DELETE /people/:id/invitation
  def revoke_invitation
    authorize @person, :revoke_invitation?

    if @person.active_invitation
      @person.active_invitation.revoke!
      render_success(message: 'Invitation revoked.')
    else
      render_error(errors: ['No active invitation found'], message: 'Nothing to revoke.')
    end
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
