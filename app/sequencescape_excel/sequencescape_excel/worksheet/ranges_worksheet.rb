# frozen_string_literal: true

module SequencescapeExcel
  module Worksheet
    ##
    # Ranges worksheet
    class RangesWorksheet < Base
      self.worksheet_name = 'Ranges'
      # Using axlsx worksheet creates worksheet with all the ranges listed on worksheet.
      # Also updates ranges with absolute reference (adds worksheet name to ranges references, i.e. 'Ranges!$A$5:$F$5'),
      # so that the ranges could be passed in and used in data worksheet (data validations and
      # conditional formattings use ranges absolute references in formulas).

      def create_worksheet
        super
        add_ranges
        ranges.set_worksheet_names(name)
      end

      # Adds ranges on the worksheet. One range one row.

      def add_ranges
        ranges.each { |_k, range| add_row range.options }
        self
      end
    end
  end
end
