# frozen_string_literal: true

class IssueSerializer
  include JSONAPI::Serializer

  attributes :id,
             :title,
             :description,
             :notes,
             :tags,
             :status,
             :closed_at,
             :created_at,
             :updated_at

  attribute :clients do |issue|
    issue.client_issues.includes(:client, :shared_by).map do |ci|
      {
        id:           ci.client.id,
        display_name: ci.client.display_name,
        shared_at:    ci.shared_at,
        shared_by:    ci.shared_by ? { id: ci.shared_by.id, email: ci.shared_by.email } : nil
      }
    end
  end

  attribute :people do |issue|
    issue.issue_people.joins(:person).includes(:person).order('people.last_name ASC').map do |ip|
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

  attribute :people_count do |issue|
    issue.issue_people.size
  end

  attribute :created_by do |issue|
    issue.created_by ? { id: issue.created_by.id, email: issue.created_by.email } : nil
  end

  attribute :updated_by do |issue|
    issue.updated_by ? { id: issue.updated_by.id, email: issue.updated_by.email } : nil
  end

  attribute :closed_by do |issue|
    issue.closed_by ? { id: issue.closed_by.id, email: issue.closed_by.email } : nil
  end
end
