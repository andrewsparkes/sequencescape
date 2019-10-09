# frozen_string_literal: true

FactoryBot.define do
  factory :taxon_lookup_taxon, class: TaxonLookup::Taxon do
    taxon_id { 9606 }

    initialize_with { new(taxon_id) }
    skip_create
  end
end
