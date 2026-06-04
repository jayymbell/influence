# frozen_string_literal: true

class BillPolicy < ApplicationPolicy
  def index?
    admin_or_staff? || user.manager?
  end

  def show?
    admin_or_staff? || manager_on_bill?
  end

  def create?
    admin_or_staff? || user.manager?
  end

  def update?
    admin_or_staff? || manager_on_bill?
  end

  def destroy?
    admin_or_staff? || manager_on_bill?
  end

  def search?
    admin_or_staff? || user.manager?
  end

  def import?
    admin_or_staff? || user.manager?
  end

  def link_external?
    admin_or_staff? || manager_on_bill?
  end

  def refresh?
    admin_or_staff? || manager_on_bill?
  end

  def watch?
    admin_or_staff? || user.manager?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.staff?
        scope.all
      elsif user.manager?
        client_ids = ClientStaff.where(user_id: user.id).pluck(:client_id)
        bill_ids   = BillClient.where(client_id: client_ids).pluck(:bill_id)
        scope.where(id: bill_ids)
      else
        scope.none
      end
    end
  end

  private

  def admin_or_staff?
    user.admin? || user.staff?
  end

  def manager_on_bill?
    return false unless user.manager?

    client_ids = ClientStaff.where(user_id: user.id).pluck(:client_id)
    BillClient.where(bill_id: record.id, client_id: client_ids).exists?
  end
end
