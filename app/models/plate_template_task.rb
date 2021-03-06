# frozen_string_literal: true

# Handles display of plate template options (first page of cherrypicking)
# and the processing of any uploaded spreadsheets to set a layout
class PlateTemplateTask < Task
  include Tasks::PlatePurposeBehavior

  # Class to extract the layout from an uploaded spreadsheet
  class SpreadsheetReader
    def initialize(csv_string, batch, plate_size)
      @csv_string = csv_string
      @requests = batch.requests.includes(asset: [:map, { plate: :barcodes }]).index_by(&:id)
      @plate_size = plate_size
    end

    def layout
      barcodes = Set.new
      plates = mapped_plate_wells.each_value.map do |mapped_wells|
        Array.new(plate_size) do |i|
          request_id = mapped_wells[i]
          if request_id.present?
            asset = requests[request_id].asset
            barcodes << asset.plate.barcode_number
            [request_id, asset.plate.barcode_number, asset.display_name]
          else
            CherrypickTask::EMPTY_WELL
          end
        end
      end

      [plates, barcodes.to_a]
    end

    private

    def mapped_plate_wells
      (Hash.new { |h, k| h[k] = {} }).tap do |parsed_plates|
        CSV.parse(csv_string, headers: :first_row) do |row|
          parse_spreadsheet_row(row['Request ID'], row['Plate'], row['Destination Well']) do |plate_key, request_id, location|
            parsed_plates[plate_key][location.column_order] = request_id
          end
        end
      end
    end

    def parse_spreadsheet_row(request_id, plate_key, destination_well)
      return if request_id.blank? || request_id.to_i.zero?

      location = locations[destination_well] || return
      yield(plate_key.presence || 'default plate 1', request_id.to_i, location)
    end

    def locations
      @locations ||= Map.where(asset_size: plate_size).index_by(&:description)
    end

    attr_reader :requests, :plate_size, :csv_string
  end

  # Presenter, seemingly used in DnaQCHandler
  class PlateTemplateData < Task::RenderElement
    attr_reader :testing
    alias_attribute :well, :asset
  end

  def create_render_element(request)
    request.asset && PlateTemplateData.new(request)
  end

  def partial
    'plate_template_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_plate_template_task(self, params)
  end

  def do_task(workflows_controller, params)
    return true if params[:file].blank?

    plate_size = if params[:plate_template].blank?
                   PlatePurpose.find(params[:plate_purpose_id]).size
                 else
                   PlateTemplate.find(params[:plate_template]['0'].to_i).size
                 end
    workflows_controller.spreadsheet_layout = SpreadsheetReader.new(params[:file].read, workflows_controller.batch, plate_size).layout
    true
  end
end
