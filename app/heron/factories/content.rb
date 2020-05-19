# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron wells content in a plate
    class Content
      include ActiveModel::Model
      include Concerns::CoordinatesSupport

      validate :sample_factories

      attr_accessor :study_uuid

      def initialize(params, study_uuid = nil)
        @params = params
        @study_uuid = study_uuid
      end

      def sample_factories
        return [] unless @params

        @sample_factories ||= @params.keys.each_with_object({}) do |location, memo|
          unless coordinate_valid?(location)
            errors.add(:coordinate, "Invalid coordinate format (#{location})")
            next
          end
          samples_params = [@params[location]].flatten.compact
          memo[unpad_coordinate(location)] = _sample_factories_for_location(location, samples_params)
        end
      end

      def _sample_factories_for_location(location, samples_params)
        samples_params.each_with_index.map do |sample_params, pos|
          label = samples_params.length == 1 ? location : "#{location}, pos: #{pos}"
          sample_params = sample_params.merge(study_uuid: study_uuid) if study_uuid
          factory = ::Heron::Factories::Sample.new(sample_params)
          errors.add(label, factory.errors.full_messages) unless factory.valid?
          factory
        end
      end

      def add_aliquots_into_locations(containers_for_locations)
        sample_factories.each do |location, factories|
          container = containers_for_locations[location]
          factories.each do |factory|
            factory.create_aliquot_at(container) if factory.valid?
          end
        end
        true
      end
    end
  end
end
