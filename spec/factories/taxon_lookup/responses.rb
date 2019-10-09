# frozen_string_literal: true

require Rails.root.join('spec', 'support', 'mock_taxon_lookup')

FactoryBot.define do
  factory :taxon_lookup_response, class: TaxonLookup::Response do
    response { MockTaxonLookup::Response.new(400, '') }

    initialize_with { new(response) }

    factory :successful_taxon_lookup_response do
      response { MockTaxonLookup.successful_taxon_lookup_response }
    end

    factory :failed_taxon_lookup_response do
      response { MockTaxonLookup.failed_taxon_lookup_response }
    end

    skip_create
  end
end
