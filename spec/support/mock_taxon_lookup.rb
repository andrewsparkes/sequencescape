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

  def failed_taxon_lookup_response
    Response.new(
      404,
      'Not Found'
    )
  end

  module_function :successful_taxon_lookup_response, :failed_taxon_lookup_response
end
