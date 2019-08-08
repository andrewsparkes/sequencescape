# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # ChromiumTagWell
    class ChromiumTagWell
      TAGS_PER_WELL = 4

      include Base

      attr_accessor :sf_tag_group

      validates :well_index, presence: { message: 'is not valid' }
      validates :tags, length: { is: TAGS_PER_WELL, message: 'does not have associated tags' }, if: :well_index

      def update(_attributes = {})
        return unless valid?

        tags.each { |tag| tag.multitag!(asset) }
      end

      def link(other_fields)
        self.sf_tag_group = other_fields[SequencescapeExcel::SpecialisedField::ChromiumTagGroup]
      end

      private

      def well_index
        @well_index = Map::Coordinate.description_to_vertical_plate_position(value, 96)
      end

      def map_ids
        Array.new(TAGS_PER_WELL) { |i| ((well_index - 1) * TAGS_PER_WELL) + i + 1 }
      end

      def tags
        Tag.where(tag_group_id: sf_tag_group.tag_group_id, map_id: map_ids) if sf_tag_group&.tag_group_id
      end
    end
  end
end
