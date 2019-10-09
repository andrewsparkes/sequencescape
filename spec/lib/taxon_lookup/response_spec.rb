# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxonLookup::Response, type: :model do
  include MockTaxonLookup

  context 'when successful lookup' do
    it 'is successful if the status code is in the correct range' do
      expect(described_class.new(MockTaxonLookup::Response.new(200, '{}'))).to be_success
      expect(described_class.new(MockTaxonLookup::Response.new(404, 'Not Found'))).not_to be_success
    end

    it 'has a common name if lookup has been successful' do
      response = described_class.new(successful_taxon_lookup_response)
      expect(response).to be_success
      expect(response.common_name).to eq('human')
      expect(response.errors).not_to be_present
    end
  end

  context 'when failed lookup' do
    it 'is a failure if the status code is in the correct range' do
      expect(described_class.new(MockTaxonLookup::Response.new(200, '{}'))).not_to be_failure
      expect(described_class.new(MockTaxonLookup::Response.new(404, 'Not Found'))).to be_failure
    end

    it 'if it is a failure should have no common name' do
      response = described_class.new(MockTaxonLookup::Response.new(404, 'Not Found'))
      expect(response.common_name).not_to be_present
      expect(response.errors).to eq(['Not Found'])
    end

    it 'has some errors if lookup was not successful' do
      response = described_class.new(failed_taxon_lookup_response)
      expect(response).to be_failure
      expect(response.common_name).not_to be_present
      expect(response.errors).to eq(['Not Found'])
    end
  end
end
