# frozen_string_literal: true

class TubeRack < Labware
  include Barcode::Barcodeable

  has_many :rackable_tubes, foreign_key: :labware_id, dependent: :destroy
  has_many :tubes, through: :rackable_tubes
end