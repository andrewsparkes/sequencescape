# frozen_string_literal: true

module TaxonLookup
  # A null respons will be returned if taxon lookup errors.
  class NullResponse
    def failure?
      true
    end

    def success?
      false
    end
  end
end
