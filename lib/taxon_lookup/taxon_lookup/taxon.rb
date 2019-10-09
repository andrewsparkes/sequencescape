# frozen_string_literal: true

module TaxonLookup
  # Made up of a sample, user and service
  # Used by Request to extract relevant information to send to appropriate accessioning service
  class Taxon
    include ActiveModel::Model

    attr_reader :taxon_id, :sample, :service, :response

    delegate :success?, to: :response

    validates_presence_of :taxon_id, :sample

    def initialize(taxon_id, sample)
      @taxon_id = taxon_id
      @sample = sample
      @response = TaxonLookup::NullResponse.new

      return unless valid?

      @service = TaxonLookup::Service.new
    end

    def get
      @response = TaxonLookup::Request.get(self) if valid?
    end

    def update_sample_common_name
      return unless success?

      @sample.sample_metadata.sample_common_name = response.common_name
      @sample.save!
    end
  end
end
