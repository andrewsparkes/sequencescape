# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxonLookup::Request, type: :model do
  include MockTaxonLookup

  let(:taxon) { build(:taxon_lookup_taxon) }

  it 'is not valid without a taxon' do
    expect(described_class.new(nil)).not_to be_valid
  end

  it 'has a resource' do
    expect(described_class.new(taxon).resource).not_to be_nil
  end

  context 'when setting the header and proxy' do
    let!(:proxy) { configatron.disable_web_proxy }

    before do
      configatron.proxy = 'mockproxy'
    end

    after do
      configatron.disable_web_proxy = proxy
      configatron.proxy = nil
    end

    it 'sets the headers and proxy when web proxy disabled' do
      configatron.disable_web_proxy = false
      request = described_class.new(taxon)
      expect(RestClient.proxy).to eq(configatron.proxy)
      expect(request.resource.options[:headers]).to have_key(:user_agent)
    end

    it 'sets the proxy and proxy when web proxy enabled' do
      configatron.disable_web_proxy = true
      request = described_class.new(taxon)
      expect(RestClient.proxy).not_to be_present
      expect(request.resource.options).not_to be_key(:headers)
    end
  end

  describe '#get' do
    it 'returns nothing if the taxon is not valid' do
      expect(described_class.new(nil).get).to be_nil
    end

    it 'returns nothing if an error is raised' do
      request = described_class.new(taxon)
      allow(request.resource).to receive(:get)
        .and_raise(StandardError)

      expect(request.get).not_to be_success
    end

    it 'returns a successful response if accessioning is successful' do
      request = described_class.new(taxon)
      allow(request.resource).to receive(:get)
        .and_return(successful_taxon_lookup_response)

      expect(request.get).to be_success
    end

    it 'returns a failure response if accessioning fails' do
      request = described_class.new(taxon)
      allow(request.resource).to receive(:get)
        .and_return(failed_taxon_lookup_response)

      expect(request.get).not_to be_success
    end
  end
end
