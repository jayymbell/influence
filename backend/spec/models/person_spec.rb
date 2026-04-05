require 'rails_helper'

RSpec.describe Person, type: :model do
  describe 'validations' do
    it 'is valid with required fields' do
      person = build(:person)
      expect(person).to be_valid
    end

    it 'is invalid without first_name' do
      person = build(:person, first_name: nil)
      expect(person).to be_invalid
      expect(person.errors[:first_name]).to include("can't be blank")
    end

    it 'is invalid without last_name' do
      person = build(:person, last_name: nil)
      expect(person).to be_invalid
      expect(person.errors[:last_name]).to include("can't be blank")
    end

    it 'is invalid without display_name' do
      person = build(:person, display_name: nil)
      expect(person).to be_invalid
      expect(person.errors[:display_name]).to include("can't be blank")
    end

    it 'is invalid with a malformed email' do
      person = build(:person, email: 'not-an-email')
      expect(person).to be_invalid
      expect(person.errors[:email]).to be_present
    end

    it 'is valid with a blank email' do
      person = build(:person, email: nil)
      expect(person).to be_valid
    end

    it 'is valid with a properly formatted email' do
      person = build(:person, email: 'valid@example.com')
      expect(person).to be_valid
    end
  end

  describe 'user linkage' do
    it 'allows a person without a linked user' do
      person = create(:person)
      expect(person.user).to be_nil
    end

    it 'allows linking a person to a user' do
      user = create(:user)
      person = create(:person, user: user)
      expect(person.user).to eq(user)
    end

    it 'enforces one person per user' do
      user = create(:user)
      create(:person, user: user)
      duplicate = build(:person, user: user)
      expect(duplicate).to be_invalid
      expect(duplicate.errors[:user_id]).to be_present
    end
  end

  describe 'soft delete' do
    it 'is included in kept scope when not discarded' do
      person = create(:person)
      expect(Person.kept).to include(person)
    end

    it 'is excluded from kept scope when discarded' do
      person = create(:person, :discarded)
      expect(Person.kept).not_to include(person)
    end

    it 'is included in discarded scope when discarded' do
      person = create(:person, :discarded)
      expect(Person.discarded).to include(person)
    end
  end

  describe 'associations' do
    it 'belongs to an optional user' do
      person = build(:person, user: nil)
      expect(person).to be_valid
    end

    it 'belongs to optional audit users' do
      admin = create(:user, :admin)
      person = create(:person, created_by: admin, updated_by: admin)
      expect(person.created_by).to eq(admin)
      expect(person.updated_by).to eq(admin)
    end
  end
end
