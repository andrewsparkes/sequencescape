# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # Base
    module Base
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Model

        define_method :initialize do |attributes = {}|
          super(attributes)
        end
      end

      attr_accessor :value, :sample_manifest_asset

      delegate :present?, to: :value, prefix: true
      delegate :asset, :sample, to: :sample_manifest_asset

      def update(_attributes = {}); end
    end
  end
end
