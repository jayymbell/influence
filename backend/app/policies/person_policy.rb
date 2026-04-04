class PersonPolicy < ApplicationPolicy
  def index?
    admin_or_staff?
  end

  def show?
    admin_or_staff?
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

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.roles.exists?(name: 'staff')
        scope.kept
      else
        scope.none
      end
    end
  end

  private

  def admin_or_staff?
    user.admin? || user.roles.exists?(name: 'staff')
  end
end
