class PersonSerializer
  include JSONAPI::Serializer

  attributes :id,
             :first_name,
             :last_name,
             :display_name,
             :email,
             :phone,
             :title,
             :organization_name,
             :notes,
             :discarded_at,
             :deactivated_at,
             :created_at,
             :updated_at

  attribute :user do |person|
    if person.user
      { id: person.user.id, email: person.user.email }
    end
  end

  attribute :created_by do |person|
    person.created_by ? { id: person.created_by.id, email: person.created_by.email } : nil
  end

  attribute :updated_by do |person|
    person.updated_by ? { id: person.updated_by.id, email: person.updated_by.email } : nil
  end

  attribute :deactivated_by do |person|
    person.deactivated_by ? { id: person.deactivated_by.id, email: person.deactivated_by.email } : nil
  end

  attribute :user_id do |person|
    person.user_id
  end

  attribute :invitation_pending do |person|
    person.association(:active_invitation).loaded? ?
      person.active_invitation.present? :
      person.invitations.active.exists?
  end
end
