# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Issue, type: :model do
  subject(:issue) { build(:issue) }

  describe 'validations' do
    it 'is valid with required attributes' do
      expect(issue).to be_valid
    end

    it 'requires title' do
      issue.title = nil
      expect(issue).not_to be_valid
      expect(issue.errors[:title]).to be_present
    end

    it 'requires title to be at least 2 characters' do
      issue.title = 'A'
      expect(issue).not_to be_valid
      expect(issue.errors[:title]).to be_present
    end

    it 'requires a client' do
      issue.client = nil
      expect(issue).not_to be_valid
    end
  end

  describe 'status enum' do
    it 'defaults to active' do
      expect(issue.status).to eq('active')
    end

    it 'can be set to inactive' do
      issue.status = :inactive
      expect(issue.inactive?).to be true
    end

    it 'can be set to closed' do
      issue.status = :closed
      expect(issue.closed?).to be true
    end
  end

  describe 'associations' do
    it 'has many client_issues' do
      issue = create(:issue)
      client2 = create(:client)
      create(:client_issue, issue: issue, client: client2)
      expect(issue.client_issues.count).to eq(1)
    end

    it 'has many issue_people' do
      issue  = create(:issue)
      person = create(:person)
      create(:issue_person, issue: issue, person: person)
      expect(issue.people.count).to eq(1)
    end
  end

  describe 'tags' do
    it 'stores and returns an array of tags' do
      issue = create(:issue, :with_tags)
      expect(issue.reload.tags).to eq(%w[healthcare transportation])
    end

    it 'defaults to an empty array' do
      issue = create(:issue)
      expect(issue.reload.tags).to eq([])
    end
  end
end
