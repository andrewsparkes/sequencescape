# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxonLookup::Taxon, type: :model do
  let!(:sample) { build(:accessioned_sample) }

  context 'when initializing' do
    it 'is not valid unless a taxon id is present' do
      expect(described_class.new(nil, sample)).not_to be_valid
    end

    it 'is not valid unless a sample is present' do
      expect(described_class.new(1234, nil)).not_to be_valid
    end

    it 'is valid if both a taxon id and sample are present' do
      expect(described_class.new(1234, sample)).to be_valid
    end
  end

  context 'when getting taxon details from the service' do
    let(:taxon) { described_class.new(1234, sample) }

    before do
      configatron.accession_samples = true
      Delayed::Worker.delay_jobs = false
      Accession.configure do |config|
        config.folder = File.join('spec', 'data', 'taxon_lookup')
        config.load!
      end
      allow(Accession::Request).to receive(:post).and_return(build(:successful_accession_response))
    end

    after do
      Delayed::Worker.delay_jobs = true
      configatron.accession_samples = false
    end

    context 'when successful' do
      before do
        allow(TaxonLookup::Request).to receive(:get).with(taxon).and_return(build(:successful_taxon_lookup_response))
        taxon.get
      end

      it 'returns an appropriate response' do
        expect(taxon).to be_success
      end

      it 'can update sample common name' do
        taxon.update_sample_common_name
        expect(taxon.sample.sample_metadata.sample_common_name).to eq('human')
      end
    end

    context 'when failure' do
      before do
        allow(TaxonLookup::Request).to receive(:get).with(taxon).and_return(build(:failed_taxon_lookup_response))
        taxon.get
      end

      it 'returns an appropriate response' do
        expect(taxon).not_to be_success
      end
    end
  end
end
