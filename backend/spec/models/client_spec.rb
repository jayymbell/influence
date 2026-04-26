# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Client, type: :model do
  subject(:client) { build(:client) }

  describe 'validations' do
    it 'is valid with required attributes' do
      expect(client).to be_valid
    end

    it 'requires legal_name' do
      client.legal_name = nil
      expect(client).not_to be_valid
      expect(client.errors[:legal_name]).to be_present
    end

    it 'requires legal_name to be at least 2 characters' do
      client.legal_name = 'A'
      expect(client).not_to be_valid
      expect(client.errors[:legal_name]).to be_present
    end

    it 'requires display_name' do
      client.display_name = nil
      expect(client).not_to be_valid
      expect(client.errors[:display_name]).to be_present
    end
  end

  describe 'duplicate name prevention' do
    it 'prevents duplicate legal names (case-insensitive)' do
      create(:client, legal_name: 'Acme Corp')
      duplicate = build(:client, legal_name: 'acme corp')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:legal_name]).to be_present
    end

    it 'prevents duplicate legal names even when existing client is inactive' do
      create(:client, :discarded, legal_name: 'Acme Corp')
      new_client = build(:client, legal_name: 'Acme Corp')
      expect(new_client).not_to be_valid
    end

    it 'allows updating a client without triggering duplicate error on itself' do
      client = create(:client, legal_name: 'Acme Corp')
      expect(client.update(display_name: 'Acme')).to be true
    end
  end

  describe '#status' do
    it 'returns active when not discarded' do
      expect(client.status).to eq('active')
    end

    it 'returns inactive when discarded' do
      client.discarded_at = Time.current
      expect(client.status).to eq('inactive')
    end
  end

  describe 'soft delete' do
    it 'excludes discarded clients from kept scope' do
      active   = create(:client)
      inactive = create(:client, :discarded)

      expect(Client.kept).to include(active)
      expect(Client.kept).not_to include(inactive)
    end

    it 'includes discarded clients in discarded scope' do
      inactive = create(:client, :discarded)
      expect(Client.discarded).to include(inactive)
    end
  end
end
