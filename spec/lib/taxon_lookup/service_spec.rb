# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxonLookup::Service, type: :model do
  context 'when creating URLs' do
    let(:service) { described_class.new }

    it 'has a base url' do
      expect(service.url).to be_present
    end

    it 'has a uri option for fetch taxon by id' do
      expect(service.fetch_taxon_by_id).to be_present
    end
  end
end
