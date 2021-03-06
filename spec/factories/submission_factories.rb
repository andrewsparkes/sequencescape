# frozen_string_literal: true

FactoryBot.define do
  factory :submission__ do
    user
    factory :submission_without_order
  end

  factory :submission do
    user
  end

  factory :submission_template do
    transient do
      request_type_ids_list { request_types.map { |rt| [rt.id] } }
      request_types { [] }
    end

    submission_class_name { LinearSubmission.name }
    sequence(:name) { |i| "Template #{i}" }
    submission_parameters { { request_type_ids_list: request_type_ids_list } }
    product_catalogue { |pc| pc.association(:single_product_catalogue) }

    factory :limber_wgs_submission_template do
      transient do
        request_types { [create(:library_request_type)] }
      end
    end

    factory :libray_and_sequencing_template do
      transient do
        request_types { [create(:library_request_type), create(:sequencing_request_type)] }
      end
    end
  end

  factory :order do
    study
    project
    user
    request_options {}
    # This block is enabled when we have the labware table present as part of the AssetRefactor
    # Ie. This is what will happen in future
    AssetRefactor.when_refactored do
      assets  { create_list(:sample_tube, 1).map(&:receptacle) }
    end
    # This block is disabled when we have the labware table present as part of the AssetRefactor
    # Ie. This is what will happens now
    AssetRefactor.when_not_refactored do
      assets  { create_list(:sample_tube, 1) }
    end
    request_types { [create(:request_type).id] }

    factory :order_with_submission do
      after(:build) { |o| o.create_submission(user_id: o.user_id) }
    end
  end

  factory :linear_submission do
    study
    project
    user
    submission
    # This block is enabled when we have the labware table present as part of the AssetRefactor
    # Ie. This is what will happen in future
    AssetRefactor.when_refactored do
      assets  { create_list(:sample_tube, 1).map(&:receptacle) }
    end
    # This block is disabled when we have the labware table present as part of the AssetRefactor
    # Ie. This is what will happens now
    AssetRefactor.when_not_refactored do
      assets  { create_list(:sample_tube, 1) }
    end
    request_types { [create(:request_type).id] }

    factory :library_order do
      assets { create_list :untagged_well, 1 }
      request_types { [create(:library_request_type).id] }
      request_options { { fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: 'Standard' } }
    end
  end

  factory :flexible_submission do
    study
    project
    user
    submission
    # This block is enabled when we have the labware table present as part of the AssetRefactor
    # Ie. This is what will happen in future
    AssetRefactor.when_refactored do
      assets  { create_list(:sample_tube, 1).map(&:receptacle) }
    end
    # This block is disabled when we have the labware table present as part of the AssetRefactor
    # Ie. This is what will happens now
    AssetRefactor.when_not_refactored do
      assets  { create_list(:sample_tube, 1) }
    end
    request_types { [create(:request_type).id] }
  end

  factory :automated_order do
    user
    request_types { create_list(:sequencing_request_type, 1).map(&:id) }
    # This block is enabled when we have the labware table present as part of the AssetRefactor
    # Ie. This is what will happen in future
    AssetRefactor.when_refactored do
      assets  { create_list(:library_tube, 1).map(&:receptacle) }
    end
    # This block is disabled when we have the labware table present as part of the AssetRefactor
    # Ie. This is what will happens now
    AssetRefactor.when_not_refactored do
      assets  { create_list(:library_tube, 1) }
    end
  end

  # Builds a submission on the provided assets suitable for processing through
  # an external library pipeline such as Limber
  # Note: Not yet complete. (Just in case something crops up before I finish this!)
  factory :library_submission, class: Submission do
    transient do
      assets { [create(:well)] }
      request_types { [create(:library_request_type), create(:multiplex_request_type)] }
    end

    user
    after(:build) do |submission, evaluator|
      submission.orders << build(:library_order, assets: evaluator.assets, request_types: evaluator.request_types.map(&:id))
    end
  end
end

class FactoryHelp
  def self.submission(options)
    submission_options = {}
    [:message, :state].each do |option|
      value = options.delete(option)
      submission_options[option] = value if value
    end
    submission = FactoryBot.create(:order_with_submission, options).submission
    # trying to skip StateMachine
    submission.update!(submission_options) if submission_options.present?
    submission.reload
  end
end
