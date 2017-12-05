# We'll try and do this through the API with the live version

namespace :limber do
  desc 'Create the Limber cherrypick plate'
  task create_plates: :environment do
    # Caution: This is provided to help setting up limber development environments
    unless Purpose.where(name: 'LB Cherrypick').exists?
      puts 'Caution! Limber purposes do not exist. Creating LB Cherrypick plate.'
      puts 'Other purposes will be generated by Limber'
      PlatePurpose::Input.create!(
        name: 'LB Cherrypick',
        target_type: 'Plate',
        qc_display: false,
        stock_plate: true,
        default_state: 'pending',
        barcode_printer_type_id: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: true,
        cherrypickable_source: false,
        cherrypick_direction: 'column',
        size: 96,
        asset_shape: AssetShape.default,
        barcode_for_tecan: 'ean13_barcode'
      )
    end
  end

  desc 'Create the limber request types'
  task create_request_types: [:environment, :create_plates] do
    puts 'Creating request types...'
    ActiveRecord::Base.transaction do
      ['WGS', 'LCMB'].each do |prefix|
        Limber::Helper::RequestTypeConstructor.new(prefix).build!
      end
      Limber::Helper::RequestTypeConstructor.new('PCR Free', default_purpose: 'PF Cherrypicked').build!

      Limber::Helper::RequestTypeConstructor.new(
        'ISC',
        request_class: 'Pulldown::Requests::IscLibraryRequest',
        library_types: ['Agilent Pulldown']
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'ReISC',
        request_class: 'Pulldown::Requests::ReIscLibraryRequest',
        library_types: 'Agilent Pulldown',
        default_purpose: 'LB Lib PCR-XP'
      ).build!

      unless RequestType.where(key: 'limber_multiplexing').exists?
        RequestType.create!(
          name: 'Limber Multiplexing',
          key: 'limber_multiplexing',
          request_class_name: 'Request::Multiplexing',
          for_multiplexing: true,
          workflow: Submission::Workflow.find_by(name: 'Next-gen sequencing'),
          asset_type: 'Well',
          order: 2,
          initial_state: 'pending',
          billable: false,
          product_line: ProductLine.find_by(name: 'Illumina-Htp'),
          request_purpose: RequestPurpose.standard,
          target_purpose: Purpose.find_by(name: 'LB Lib Pool Norm')
        )
      end
    end
  end

  desc 'Create the limber searches'
  task create_searches: [:environment] do
    Search::FindPlates.create_with(default_parameters: {limit: 30}).find_or_create_by!(name: 'Find plates')
  end

  desc 'Create the limber submission templates'
  task create_submission_templates: [:environment, :create_request_types] do
    puts 'Creating submission templates....'
    ActiveRecord::Base.transaction do
      %w(WGS ISC ReISC).each do |suffix|
        catalogue = ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: suffix)
        Limber::Helper::TemplateConstructor.new(suffix: suffix, catalogue: catalogue).build!
      end
      # PCR Free is HiSeqX only
      'PCR Free'.tap do |prefix|
        catalogue = ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'PFHSqX')
        Limber::Helper::TemplateConstructor.new(
          name: prefix,
          role: prefix,
          type: "limber_#{prefix.downcase.tr(' ', '_')}",
          catalogue: catalogue,
          sequencing: ['illumina_b_hiseq_x_paired_end_sequencing']
        ).build!
      end
    end
    lcbm_catalogue = ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'LCMB')
    Limber::Helper::LibraryOnlyTemplateConstructor.new(suffix: 'LCMB', catalogue: lcbm_catalogue).build!
    catalogue = ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'Generic')
    Limber::Helper::TemplateConstructor.new(suffix: 'Multiplexing', catalogue: catalogue).build!
  end
end
