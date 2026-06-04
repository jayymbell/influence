# frozen_string_literal: true

class BillNotePolicy < ApplicationPolicy
  # record is a BillNote

  def show?
    record.shared? || record.user_id == user.id
  end

  def update?
    admin_or_staff? || record.user_id == user.id
  end

  def destroy?
    admin_or_staff? || record.user_id == user.id
  end

  def share?
    admin_or_staff? || record.user_id == user.id
  end

  def unshare?
    user.admin? || record.user_id == user.id
  end

  def pin?
    admin_or_staff?
  end

  private

  def admin_or_staff?
    user.admin? || user.staff?
  end
end
