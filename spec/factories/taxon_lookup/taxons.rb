# frozen_string_literal: true

FactoryBot.define do
  factory :taxon_lookup_taxon, class: TaxonLookup::Taxon do
    taxon_id { 9606 }
    sample { build(:accessioned_sample) }

    initialize_with { new(taxon_id, sample) }
    skip_create
  end
end
