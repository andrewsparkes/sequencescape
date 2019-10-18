# frozen_string_literal: true

module MockTaxonLookup
  Response = Struct.new(:code, :body)

  def successful_taxon_lookup_response
    Response.new(
      200,
      '{
        "taxId": "9606",
        "scientificName": "Homo sapiens",
        "commonName": "human",
        "formalName": "true",
        "rank": "species",
        "division": "HUM",
        "lineage": "Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Euarchontoglires; Primates; Haplorrhini; Catarrhini; Hominidae; Homo; ",
        "geneticCode": "1",
        "mitochondrialGeneticCode": "2",
        "submittable": "true"
      }'
    )
  end

  def successful_taxon_lookup_response_without_common_name
    Response.new(
      200,
      '{
        "taxId": "1313",
        "scientificName": "Streptococcus pneumoniae",
        "formalName": "true",
        "rank": "species",
        "division": "PRO",
        "lineage": "Bacteria; Firmicutes; Bacilli; Lactobacillales; Streptococcaceae; Streptococcus; ",
        "geneticCode": "11",
        "submittable": "true"
      }'
    )
  end

  def successful_taxon_lookup_response_unsubmittable
    Response.new(
      200,
      '{
        "taxId": "2",
        "scientificName": "Bacteria",
        "commonName": "eubacteria",
        "formalName": "false",
        "rank": "superkingdom",
        "division": "PRO",
        "geneticCode": "11",
        "submittable": "false"
      }'
    )
  end

  def failed_taxon_lookup_response
    Response.new(
      404,
      'Not Found'
    )
  end

  module_function :successful_taxon_lookup_response,
                  :successful_taxon_lookup_response_without_common_name,
                  :successful_taxon_lookup_response_unsubmittable,
                  :failed_taxon_lookup_response
end
