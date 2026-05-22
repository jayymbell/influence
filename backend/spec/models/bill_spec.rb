# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bill, type: :model do
  describe 'validations' do
    it 'is valid with a title' do
      bill = build(:bill, title: 'Test Bill')
      expect(bill).to be_valid
    end

    it 'requires a title' do
      bill = build(:bill, title: nil)
      expect(bill).not_to be_valid
      expect(bill.errors[:title]).to be_present
    end

    it 'requires title of at least 2 characters' do
      bill = build(:bill, title: 'X')
      expect(bill).not_to be_valid
      expect(bill.errors[:title]).to be_present
    end

    it 'is invalid with an unknown status' do
      expect { build(:bill, status: :unknown) }.to raise_error(ArgumentError)
    end

    it 'is invalid with an unknown chamber' do
      expect { build(:bill, chamber: :nope) }.to raise_error(ArgumentError)
    end

    it 'defaults status to introduced' do
      bill = build(:bill)
      expect(bill.status).to eq('introduced')
    end
  end

  describe 'enums' do
    it 'defines all 10 statuses' do
      expected = %w[introduced in_committee passed_committee floor_vote passed_chamber
                    passed_both_chambers signed vetoed failed carried_over]
      expect(Bill.statuses.keys).to match_array(expected)
    end

    it 'defines house and senate chambers' do
      expect(Bill.chambers.keys).to match_array(%w[house senate])
    end
  end

  describe 'associations' do
    it 'has_many bill_issues' do
      bill  = create(:bill)
      issue = create(:issue)
      create(:bill_issue, bill: bill, issue: issue)
      expect(bill.issues).to include(issue)
    end

    it 'has_many bill_clients' do
      bill   = create(:bill)
      client = create(:client)
      create(:bill_client, bill: bill, client: client)
      expect(bill.clients).to include(client)
    end

    it 'has_many bill_people' do
      bill   = create(:bill)
      person = create(:person)
      create(:bill_person, bill: bill, person: person)
      expect(bill.people).to include(person)
    end

    it 'allows a companion bill' do
      companion = create(:bill)
      bill      = create(:bill, companion_bill: companion)
      expect(bill.companion_bill).to eq(companion)
    end

    it 'prevents self-referential companion' do
      bill = create(:bill)
      bill.companion_bill_id = bill.id
      expect(bill).not_to be_valid
      expect(bill.errors[:companion_bill_id]).to be_present
    end
  end

  describe 'tags' do
    it 'defaults to an empty array' do
      bill = create(:bill)
      expect(bill.tags).to eq([])
    end

    it 'stores multiple tags' do
      bill = create(:bill, tags: %w[healthcare energy])
      expect(bill.reload.tags).to eq(%w[healthcare energy])
    end
  end
end
