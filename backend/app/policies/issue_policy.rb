# frozen_string_literal: true

class IssuePolicy < ApplicationPolicy
  def index?
    admin_or_staff? || user.manager?
  end

  def show?
    admin_or_staff? || manager_on_issue?
  end

  def create?
    admin_or_staff? || user.manager?
  end

  def update?
    admin_or_staff? || manager_on_issue?
  end

  def destroy?
    admin_or_staff? || manager_on_issue?
  end

  def close?
    admin_or_staff? || manager_on_issue?
  end

  def deactivate?
    admin_or_staff? || manager_on_issue?
  end

  def reactivate?
    admin_or_staff? || manager_on_issue?
  end

  def share?
    user.admin? || user.manager?
  end

  def unshare?
    user.admin? || user.manager?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.staff?
        scope.all
      elsif user.manager?
        client_ids = ClientStaff.where(user_id: user.id).pluck(:client_id)
        issue_ids = ClientIssue.where(client_id: client_ids).pluck(:issue_id)
        scope.where(id: issue_ids)
      else
        scope.none
      end
    end
  end

  private

  def admin_or_staff?
    user.admin? || user.staff?
  end

  def manager_on_issue?
    return false unless user.manager?

    client_ids = ClientStaff.where(user_id: user.id).pluck(:client_id)
    ClientIssue.where(issue_id: record.id, client_id: client_ids).exists?
  end
end
