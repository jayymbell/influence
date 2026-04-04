# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seed core roles
%w[admin staff].each { |name| Role.find_or_create_by!(name: name) }

# Admin user
User.find_or_initialize_by(email: 'influence-admin@example.com').tap do |user|
  user.password            ||= 'Password123!!'
  user.password_confirmation = user.password
  user.confirmed_at        ||= Time.current
    user.system_user         = true
  user.save!
  user.roles << Role.find_by!(name: 'admin') unless user.roles.exists?(name: 'admin')
end
