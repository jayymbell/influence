require 'rails_helper'

RSpec.describe Role, type: :model do
  it 'is valid with a unique name' do
    role = build(:role, name: 'unique_role')
    expect(role).to be_valid
  end

  it 'is invalid without a name' do
    role = build(:role, name: nil)
    expect(role).to be_invalid
    expect(role.errors[:name]).to include("can't be blank")
  end

  it 'enforces uniqueness of name' do
    create(:role, name: 'duplicate')
    dup = build(:role, name: 'duplicate')
    expect(dup).to be_invalid
    expect(dup.errors[:name]).to include('has already been taken')
  end
end
