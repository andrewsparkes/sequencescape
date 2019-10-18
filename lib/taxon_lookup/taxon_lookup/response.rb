# frozen_string_literal: true

module TaxonLookup
  # Extracts taxon attributes from the Taxonomy Service RestClient response
  class Response
    include ActiveModel::Validations

    attr_reader :code, :body, :taxon_details

    validates_presence_of :code, :body

    # Extracts the response code and body from response and parses the JSON
    def initialize(response)
      @code = response.code
      @body = response.body.to_s

      Rails.logger.debug(code)
      Rails.logger.debug(body)

      return unless successful?

      @taxon_details = JSON.parse(body)
    end

    def successful?
      code.between?(200, 300)
    end

    def failed?
      code.between?(400, 600)
    end

    def common_name
      return unless successful?

      # not all species have a common name, in these cases we fall back to the scientific name
      taxon_details['commonName'].presence || taxon_details['scientificName']
    end

    def submittable?
      return unless successful?

      taxon_details['submittable'] == 'true'
    end

    def errors
      return ['Not Found'] if failed?

      return ['Not Submittable'] if successful? && !submittable?
    end
  end
end
