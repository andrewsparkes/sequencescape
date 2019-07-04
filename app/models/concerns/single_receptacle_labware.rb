# frozen_string_literal: true

# Labware with just a single receptacle
# This is mostly compatibility methods and we should consider removing
# as we migrate
module SingleReceptacleLabware
  extend ActiveSupport::Concern

  included do
    AssetRefactor.when_refactored do
      has_one :receptacle, foreign_key: :labware_id, inverse_of: :labware, dependent: :destroy

      # Using a has_many through here complicates attempts to build aliquots
      # through the association, as it results in a
      # HasManyThroughCantAssociateThroughHasOneOrManyReflection exception
      # Although I think I might actually be doing something stupid
      delegate :aliquots, :aliquots=, to: :receptacle
      delegate :concentration, :concentration=, to: :receptacle
      # Delegate for the moment, update once things are working
      delegate :transfer_requests_as_target, :transfer_requests_as_source, to: :receptacle
      # Delegate for the moment, update once things are working
      delegate :qc_results, to: :receptacle
      # And a few more basic delegations
      delegate  :qc_state, :qc_state=,
                :external_release, :external_release=,
                :volume, :volume=,
                to: :receptacle
    end
  end

  class_methods do
  end

  # This block is enabled when we have the labware table present as part of the AssetRefactor
  # Ie. This is what will happen in future
  AssetRefactor.when_refactored do
    def receptacle
      super || build_receptacle
    end
  end
end