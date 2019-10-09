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

      return unless success?

      @taxon_details = JSON.parse(body)
    end

    def success?
      code.between?(200, 300)
    end

    def failure?
      code.between?(400, 600)
    end

    def common_name
      return unless success?

      taxon_details['commonName']
    end

    def errors
      return if success?

      [body]
    end
  end
end
