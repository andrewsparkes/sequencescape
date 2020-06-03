# frozen_string_literal: true

require 'sanger_barcode_format'
# A collection of supported formats
module Barcode::FormatHandlers
  # Include in barcode formats which can not be rendered as EAN13s
  module Ean13Incompatible
    def ean13_barcode?
      false
    end

    def ean13_barcode
      nil
    end
  end
  #
  # Base Sequencescape barcode
  # This class mostly wraps the SBCF Gem
  #
  # @author [jg16]
  #
  class SangerBase
    attr_reader :barcode_object

    def initialize(barcode)
      @barcode_object = SBCF::SangerBarcode.from_human(barcode)
    end

    delegate :human_barcode, :=~, to: :barcode_object # =~ is defined on Object, so we need to explicitly delegate
    delegate_missing_to :barcode_object

    # The gem was yielding integers for backward compatible reasons.
    # We'll convert for the time being, but should probably fix that.
    def ean13_barcode
      barcode_object.machine_barcode.to_s
    end

    def ean13_barcode?
      true
    end

    def code39_barcode?
      true
    end

    def number_as_string
      number.to_s
    end

    def code128_barcode?
      true
    end

    def barcode_prefix
      prefix.human
    end
  end

  #
  # The original Sequencescape barcode format. results in:
  # Human readable form: DN12345U
  # Ean13 compatible machine readable form: 1220012345855
  # This class mostly wraps the SBCF Gem
  #
  # @author [jg16]
  #
  class SangerEan13 < SangerBase
    # The gem was yielding integers for backward compatible reasons.
    # We'll convert for the time being, but should probably fix that.
    def machine_barcode
      ean13_barcode
    end

    alias code128_barcode machine_barcode
    alias code39_barcode machine_barcode
    alias serialize_barcode human_barcode
  end

  #
  # The revised Sequencescape barcode format. results in:
  # Human readable form: DN12345U
  # Standard code39 machine format: DN12345U
  # Ean13 fallback: 1220012345855
  # This class mostly wraps the SBCF Gem
  #
  # @author [jg16]
  #
  class SangerCode39 < SangerBase
    def machine_barcode
      human_barcode
    end

    alias code128_barcode machine_barcode
    alias code39_barcode machine_barcode
    alias serialize_barcode human_barcode
  end

  # A basic class for barodes that can be validated and decomposed by simple regular expressions
  # Classes that inherit from this should define a regular expression with optional names matchers
  # for prefix, number and suffix. This regex should be assigned to self.format
  class BaseRegExBarcode
    include Ean13Incompatible
    attr_reader :human_barcode

    class_attribute :format

    def initialize(barcode)
      @human_barcode = barcode
      @matches = format.match(@human_barcode)
    end

    def barcode_prefix
      @matches[:prefix] if @matches&.names&.include?('prefix')
    end

    def number
      @matches[:number].to_i if @matches&.names&.include?('number')
    end

    def suffix
      @matches[:suffix] if @matches&.names&.include?('suffix')
    end

    def code128_barcode?
      /\A[[:ascii:]]+\z/.match?(@human_barcode)
    end

    def code39_barcode?
      %r{\A[A-Z0-9 \-\.$\/\+%]+\z}.match?(@human_barcode)
    end

    def valid?
      format.match? @human_barcode
    end

    def code128_barcode
      human_barcode if code128_barcode?
    end

    def code39_barcode
      human_barcode if code39_barcode?
    end

    def =~(other)
      human_barcode == other
    end

    alias machine_barcode human_barcode
    alias serialize_barcode human_barcode
  end

  # Infinium barcodes are externally generated barcodes on Illumina Infinium chips
  class Infinium < BaseRegExBarcode
    # Based on ALL existing examples (bar what appears to be accidental usage of the sanger barcode in 5 cases)
    # eg. WG0000001-DNA and WG0000001-BCD
    self.format = /\A(?<prefix>WG)(?<number>[0-9]{7})-(?<suffix>[DNA|BCD]{3})\z/
  end

  # Fluidigm barcodes are externally generated barcodes present on fluidigm plates. They are ten digits long.
  class Fluidigm < BaseRegExBarcode
    # Ten digit barcode
    self.format = /\A(?<number>[0-9]{10})\z/
  end

  # External barcodes are almost always valid.
  class External < BaseRegExBarcode
    # Extract prefix numbers and suffix if the format is fairly simple.
    # - A number, surrounded by JUST letters and underscores
    self.format = /\A(?<prefix>[\w&&[^\d]]*)(?<number>\d+)(?<suffix>[\w&&[^\d]]*)\z/

    def valid?
      true
    end
  end

  # CGAP barcodes are externally generated foreign barcodes.
  class Cgap < BaseRegExBarcode
    # They have a prefix 'CGAP-', then a hex number that will grow in length.
    # The last character is a checksum hex digit.
    self.format = /\A(?<prefix>CGAP-)(?<number>[0-9a-fA-F]+)(?<suffix>[0-9a-fA-F])\z/

    def number
      # number is a hexadecimal string here
      @matches[:number] if @matches&.names&.include?('number')
    end
  end

  # CGAP plate barcodes are generated by the CGAP LIMS
  class CgapPlate < BaseRegExBarcode
    # They have a prefix 'PLTE-', then a hex number that will grow in length.
    # The last character is a checksum hex digit.
    self.format = /\A(?<prefix>PLTE)-(?<number>[0-9a-fA-F]+)\z/

    def number
      # number is a hexadecimal string here
      @matches[:number] if @matches&.names&.include?('number')
    end
  end

  # CGAP rack barcodes are generated by the CGAP LIMS
  class CgapRack < BaseRegExBarcode
    # They have a prefix 'RACK-', then a hex number that will grow in length.
    # The last character is a checksum hex digit.
    self.format = /\A(?<prefix>RACK)-(?<number>[0-9a-fA-F]+)\z/

    def number
      # number is a hexadecimal string here
      @matches[:number] if @matches&.names&.include?('number')
    end
  end

  # Aker barcodes are externally generated by Aker biomaterials service
  class AkerBarcode < BaseRegExBarcode
    self.format = /\AAKER-[0-9]*\z/
  end

  # FluidX barcodes matches a prefix of any two letters and an eight digit
  # number. No suffix.
  class FluidxBarcode < BaseRegExBarcode
    self.format = /\A(?<prefix>[A-Za-z]{2})(?<number>\d{8})\z/
  end

  # Added to support plates from UK Biocentre https://www.ukbiocentre.com/
  # as part of project Heron
  # See issue: https://github.com/sanger/sequencescape/issues/2634
  # Expected formats:
  # nnnnnnnnnnNBC (Early UK Biocenter)
  # where n is a digit
  class UkBiocentreV1 < BaseRegExBarcode
    self.format = /\A(?<number>\d{9,11})(?<suffix>NBC)\z/
  end

  # Added to support plates from UK Biocentre https://www.ukbiocentre.com/
  # as part of project Heron
  # See issue: https://github.com/sanger/sequencescape/issues/2634
  # Expected formats:
  # nnnnnnnnnANBC (Later UK Biocenter)
  # where n is a digit
  class UkBiocentreV2 < BaseRegExBarcode
    self.format = /\A(?<number>\d{9,10})(?<suffix>ANBC)\z/
  end

  # Added to support plates from UK Biocentre https://www.ukbiocentre.com/
  # as part of project Heron
  # See issue: https://github.com/sanger/sequencescape/issues/2634
  # Format identified during validation:
  # RNADWPnnn
  class UkBiocentreUnid < BaseRegExBarcode
    self.format = /\A(?<prefix>RNADWP)(?<number>\d{3})\z/
  end

  # Added to support plates from Alderley park:
  # as part of project Heron
  # See issue: https://github.com/sanger/sequencescape/issues/2634
  # Expected formats:
  # RNA_nnnn (Early Alderley park: Temporary barcodes on early plates)
  class AlderlyParkV1 < BaseRegExBarcode
    self.format = /\A(?<prefix>RNA)_(?<number>\d{4})\z/
  end

  # Added to support plates from Alderley park:
  # as part of project Heron
  # See issue: https://github.com/sanger/sequencescape/issues/2634
  # Expected formats:
  # AP-ccc-nnnnnnnn (Later Alderley park: The new permanent barcodes are AP-rna-00110029
  #                @note some RNA plates had the AP-kfr-00090016 barcode applied in error
  class AlderlyParkV2 < BaseRegExBarcode
    self.format = /\A(?<prefix>AP\-[a-z]{3})\-(?<number>\d{8})\z/
  end

  # Added to support plates from UK Biocentre https://www.ukbiocentre.com/
  # as part of project Heron
  # Expected formats:
  # RNAnnnnnnnnn
  # where n is a digit
  class UkBiocentreV3 < BaseRegExBarcode
    self.format = /\A(?<prefix>RNA)(?<number>\d+)\z/
  end
end
