# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxonLookup::Response, type: :model do
  include MockTaxonLookup

  context 'when taxon lookup is successful' do
    it 'the status code is in the correct range' do
      expect(described_class.new(MockTaxonLookup::Response.new(200, '{}'))).to be_successful
      expect(described_class.new(MockTaxonLookup::Response.new(404, 'Not Found'))).not_to be_successful
    end

    context 'when common name was returned' do
      let(:response) { described_class.new(successful_taxon_lookup_response) }

      it 'is flagged successful' do
        expect(response).to be_successful
      end

      it 'is flagged submittable' do
        expect(response).to be_submittable
      end

      it 'has a common name' do
        expect(response.common_name).to eq('human')
      end

      it 'does not have errors' do
        expect(response.errors).not_to be_present
      end
    end

    context 'when common name was not returned' do
      let(:response) { described_class.new(successful_taxon_lookup_response_without_common_name) }

      it 'is flagged successful' do
        expect(response).to be_successful
      end

      it 'is flagged submittable' do
        expect(response).to be_submittable
      end

      it 'has a common name' do
        expect(response.common_name).to eq('Streptococcus pneumoniae')
      end

      it 'does not have errors' do
        expect(response.errors).not_to be_present
      end
    end

    context 'when not submittable' do
      let(:response) { described_class.new(successful_taxon_lookup_response_unsubmittable) }

      it 'is flagged successful' do
        expect(response).to be_successful
      end

      it 'is not submittable' do
        expect(response).not_to be_submittable
      end

      it 'has a common name' do
        expect(response.common_name).to eq('eubacteria')
      end

      it 'has the expected error' do
        expect(response.errors).to eq(['Not Submittable'])
      end
    end
  end

  context 'when taxon lookup has failed' do
    it 'the status code is in the correct range' do
      expect(described_class.new(MockTaxonLookup::Response.new(200, '{}'))).not_to be_failed
      expect(described_class.new(MockTaxonLookup::Response.new(404, 'Not Found'))).to be_failed
    end

    context 'when standard failure' do
      let(:response) { described_class.new(failed_taxon_lookup_response) }

      it 'is flagged as failed' do
        expect(response).to be_failed
      end

      it 'is not successful' do
        expect(response).not_to be_successful
      end

      it 'does not have a common name' do
        expect(response.common_name).not_to be_present
      end

      it 'does not have submittable set' do
        expect(response.submittable?).not_to be_present
      end

      it 'has the expected error' do
        expect(response.errors).to eq(['Not Found'])
      end
    end
  end
end
