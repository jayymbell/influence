class PersonPolicy < ApplicationPolicy
  def index?
    admin_or_staff?
  end

  def show?
    admin_or_staff? || own_person?
  end

  def create?
    admin_or_staff? || record.user == user
  end

  def update?
    admin_or_staff? || own_person?
  end

  def destroy?
    admin_or_staff?
  end

  def invite?
    admin_or_staff?
  end

  def revoke_invitation?
    admin_or_staff?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.staff?
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

  def own_person?
    record.user_id == user.id
  end
end
