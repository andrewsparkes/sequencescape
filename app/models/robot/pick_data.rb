# frozen_string_literal: true

# Builds the information about a cherrypick for a {Batch}
class Robot::PickData
  attr_reader :batch, :user, :target_barcode

  delegate :requests, to: :batch

  def initialize(batch, target_barcode, user: batch.user)
    @batch = batch
    @target_barcode = target_barcode
    @user = user
  end

  def picking_data
    @picking_data ||= generate_picking_data
  end

  private

  def generate_picking_data
    data_object = {
      'user' => user.login,
      'time' => Time.zone.now,
      'source' => {},
      'destination' => {}
    }

    requests.includes([
      { asset: [{ plate: [:barcodes, :labware_type] }, :map] },
      { target_asset: [:map, :well_attribute, { plate: [:barcodes, :labware_type] }] }
    ])
            .passed
            .find_each do |request|
      source_plate = request.asset.plate
      target_plate = request.target_asset.plate
      source_well = request.asset
      target_well = request.target_asset

      next unless target_plate.any_barcode_matching?(target_barcode)

      full_source_barcode = source_plate.machine_barcode
      full_destination_barcode = target_plate.machine_barcode

      data_object['source'][full_source_barcode] ||= plate_information(source_plate)
      data_object['destination'][full_destination_barcode] ||= destination_plate_information(target_plate)

      data_object['destination'][full_destination_barcode]['mapping'] << {
        'src_well' => [full_source_barcode, source_well.map_description],
        'dst_well' => target_well.map_description,
        'volume' => target_well.get_picked_volume,
        'buffer_volume' => target_well.get_buffer_volume
      }
    end

    data_object
  end

  def plate_information(plate)
    plate_type = (plate.plate_type || PlateType.cherrypickable_default_type).tr('_', "\s")
    control = plate.pick_as_control?
    {
      'name' => plate_type,
      'plate_size' => plate.size,
      'control' => control
    }
  end

  def destination_plate_information(plate)
    plate_information(plate).tap do |info|
      info['mapping'] = []
    end
  end
end