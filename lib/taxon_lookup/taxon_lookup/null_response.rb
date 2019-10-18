# frozen_string_literal: true

module TaxonLookup
  # A null respons will be returned if taxon lookup errors.
  class NullResponse
    def failed?
      true
    end

    def successful?
      false
    end
  end
end
