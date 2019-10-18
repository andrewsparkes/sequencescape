# frozen_string_literal: true

module TaxonLookup
  # Used to request information from the EBI Taxonomy Service.
  # The resource will be a RestClient::Resource.
  # The EBI service will return either a single JSON structure representing the
  # taxon, or a 404 Not Found if the Taxon Id is not recognised.
  # The JSON looks like this when successful (for taxon Id 9606):
  # {
  #   "taxId": "9606",
  #   "scientificName": "Homo sapiens",
  #   "commonName": "human",
  #   "formalName": "true",
  #   "rank": "species",
  #   "division": "HUM",
  #   "lineage": "Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Euarchontoglires; Primates; Haplorrhini; Catarrhini; Hominidae; Homo; ",
  #   "geneticCode": "1",
  #   "mitochondrialGeneticCode": "2",
  #   "submittable": "true"
  # }
  # NB. A commonName may not always be available for a taxon, in which case we use scientificName.
  # NB. The taxon may not be 'submittable', which likely indicates a mistake in setting the taxon Id by the user.
  class Request
    include ActiveModel::Validations

    attr_reader :taxon, :resource

    validates_presence_of :taxon

    class_attribute :rest_client
    self.rest_client = RestClient::Resource

    def self.get(taxon)
      new(taxon).get
    end

    def initialize(taxon)
      @taxon = taxon

      return unless valid?

      @resource = rest_client.new(File.join(taxon.service.url, taxon.service.fetch_taxon_by_id, taxon.taxon_id.to_s))
      set_proxy
    end

    def get
      return unless valid?

      begin
        TaxonLookup::Response.new(resource.get)
      rescue StandardError => e
        Rails.logger.error(e.message)
        TaxonLookup::NullResponse.new
      end
    end

    private

    # This is horribe but necessary.
    # Set the proxy to ensure you don't get a bad request error.
    def set_proxy
      if configatron.disable_web_proxy == true
        RestClient.proxy = nil
      elsif configatron.fetch(:proxy).present?
        RestClient.proxy = configatron.proxy
        resource.options[:headers] = { user_agent: "Sequencescape TaxonLookup Client (#{Rails.env})" }
      elsif ENV['http_proxy'].present?
        RestClient.proxy = ENV['http_proxy']
      end
    end
  end
end
