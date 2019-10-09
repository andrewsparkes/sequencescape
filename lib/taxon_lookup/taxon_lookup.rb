# frozen_string_literal: true

# Handles lookup of Taxon information from the EBI Taxonomy Service.
# Before taxon lookup:
#  check configuration settings, in particular:
#   configatron.proxy
#   configatron.ebi_taxon_lookup_url
# Lookup steps:
#  1. Create a new TaxonLookup::Taxon passing in a taxon id e.g. myTaxon = TaxonLookup::Taxon.new(9606)
#  2. post it e.g. myTaxon.post
#  3. check the response for success e.g. myTaxon.response.success?
#  4. if successful you can extract information e.g. common_name = myTaxon.response.common_name
module TaxonLookup
  require_relative 'taxon_lookup/service'
  require_relative 'taxon_lookup/taxon'
  require_relative 'taxon_lookup/request'
  require_relative 'taxon_lookup/response'
  require_relative 'taxon_lookup/null_response'
end
