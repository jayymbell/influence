# frozen_string_literal: true

class BillSerializer
  include JSONAPI::Serializer

  attributes :id,
             :bill_number,
             :chamber,
             :session_year,
             :title,
             :description,
             :notes,
             :tags,
             :status,
             :external_id,
             :source_url,
             :last_synced_at,
             :created_at,
             :updated_at

  attribute :companion_bill do |bill|
    bill.companion_bill ? { id: bill.companion_bill.id, bill_number: bill.companion_bill.bill_number, title: bill.companion_bill.title } : nil
  end

  attribute :issues do |bill|
    bill.bill_issues.includes(:issue).map do |bi|
      next nil unless bi.issue

      {
        id:     bi.issue.id,
        title:  bi.issue.title,
        status: bi.issue.status
      }
    end.compact
  end

  attribute :issues_count do |bill|
    bill.bill_issues.size
  end

  attribute :clients do |bill|
    bill.bill_clients.includes(:client, :shared_by).map do |bc|
      {
        id:           bc.client.id,
        display_name: bc.client.display_name,
        shared_at:    bc.shared_at,
        shared_by:    bc.shared_by ? { id: bc.shared_by.id, email: bc.shared_by.email } : nil
      }
    end
  end

  attribute :clients_count do |bill|
    bill.bill_clients.size
  end

  attribute :people do |bill|
    bill.bill_people.joins(:person).includes(:person).order('people.organization_name ASC, people.last_name ASC').map do |bp|
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

  attribute :people_count do |bill|
    bill.bill_people.size
  end

  attribute :created_by do |bill|
    bill.created_by ? { id: bill.created_by.id, email: bill.created_by.email } : nil
  end

  attribute :updated_by do |bill|
    bill.updated_by ? { id: bill.updated_by.id, email: bill.updated_by.email } : nil
  end
end
