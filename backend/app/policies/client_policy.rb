# frozen_string_literal: true

class ClientPolicy < ApplicationPolicy
  def index?
    admin_or_staff? || user.manager?
  end

  def show?
    admin_or_staff? || user.manager?
  end

  def create?
    admin_or_staff?
  end

  def update?
    admin_or_staff?
  end

  def destroy?
    admin_or_staff?
  end

  def reactivate?
    admin_or_staff?
  end

  def manage_staff?
    user.admin? || user.manager?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.staff? || user.manager?
        scope.all
      else
        scope.none
      end
    end
  end

  private

  def admin_or_staff?
    user.admin? || user.staff?
  end
end
