# frozen_string_literal: true

module RoleHelpers
  def admin_user
    @admin_user ||= begin
      user = create(:user)
      admin_role = Role.find_or_create_by!(name: 'admin') do |r|
        r.description = 'Administrator'
      end
      user.roles << admin_role unless user.roles.exists?(name: 'admin')
      user
    end
  end

  def create_user_with_role(role_name, **user_attrs)
    user = create(:user, **user_attrs)
    role = Role.find_or_create_by!(name: role_name) do |r|
      r.description = "#{role_name.capitalize} role"
    end
    user.roles << role unless user.roles.exists?(name: role_name)
    user
  end
end

RSpec.configure do |config|
  config.include RoleHelpers
end
