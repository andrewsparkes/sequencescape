# frozen_string_literal: true

module TaxonLookup
  # Used by TaxonLookup::Request to contact the EBI Taxonomy service.
  # Contains anyything specific to contacting the service.
  # No logon is required.
  # The service has a number of options (see https://www.ebi.ac.uk/ena/browse/taxonomy-service).
  class Service
    include ActiveModel::Validations

    # Base URL for the EBI Taxonomy service. Append a uri option to this.
    def url
      configatron.ebi_taxonomy_service.base.url!
    end

    # uri component for the 'Fetch Taxon by Id' option of the EBI Taxonomy service
    # which requires an NCBI taxonomic ID
    def fetch_taxon_by_id
      configatron.ebi_taxonomy_service.opt.fetch_taxon_by_id!
    end
  end
end
