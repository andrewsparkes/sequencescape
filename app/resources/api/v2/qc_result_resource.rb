# frozen_string_literal: true

module Api
  module V2
    class QcResultResource < JSONAPI::Resource

      attributes :key, :value, :units, :cv, :assay_type, :assay_version
    end
  end
end
