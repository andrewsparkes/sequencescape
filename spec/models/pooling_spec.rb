require 'rails_helper'

describe Pooling, type: :model do
  let(:empty_lb_tube) { create :empty_library_tube, barcode: 1 }
  let(:untagged_lb_tube1) { create :library_tube, barcode: 2 }
  let(:untagged_lb_tube2) { create :library_tube, barcode: 3 }
  let(:tagged_lb_tube1) { create :tagged_library_tube, barcode: 4 }
  let(:tagged_lb_tube2) { create :tagged_library_tube, barcode: 5 }
  let(:mx_tube) { create :multiplexed_library_tube, barcode: 6 }
  let(:stock_mx_tube_required) { false }
  let(:barcode_printer_option) { nil }
  let(:pooling) { Pooling.new(barcodes: barcodes, stock_mx_tube_required: stock_mx_tube_required, barcode_printer: barcode_printer_option) }

  context 'without source assets' do
    let(:barcodes) { [] }

    it 'is not valid without source_assets' do
      expect(pooling).not_to be_valid
      expect(pooling.errors.full_messages).to include 'Source assets were not scanned or were not found in sequencescape'
    end
  end

  context 'with a series of invalid assets' do
    let(:barcodes) { ['-1', '-2', empty_lb_tube.ean13_barcode, untagged_lb_tube1.human_barcode, untagged_lb_tube2.ean13_barcode] }

    it 'is not valid if tubes are not in sqsc, if tubes do not have at least one aliquot or if there is a tag clash' do
      expect(pooling).not_to be_valid
      expect(pooling.errors.messages.count).to eq 2
      expect(pooling.errors.full_messages).to include 'Source assets with barcode(s) -1, -2 were not found in sequencescape'
      expect(pooling.errors.full_messages).to include "Source assets with barcode(s) #{empty_lb_tube.ean13_barcode} do not have any aliquots"
      expect(pooling.errors.full_messages).to include 'Tags combinations Same tags  are used on rows 2, 3.'
    end
  end

  describe '#execute' do
    let(:barcodes) { [tagged_lb_tube1.ean13_barcode, tagged_lb_tube2.ean13_barcode, untagged_lb_tube1.ean13_barcode, mx_tube.ean13_barcode] }

    before do
      create_list(:single_tagged_aliquot, 2, receptacle: mx_tube)
    end

    it 'is valid if tubes are in sqsc, have at least 1 aliquot and there is no tag clash' do
      expect(pooling).to be_valid
    end

    it 'creates only standard mx tube if stock is not required' do
      expect(pooling.execute).to be true
      expect(pooling.stock_mx_tube.present?).to be false
      expect(pooling.standard_mx_tube.aliquots.count).to eq 5
      expect(pooling.message).to eq(notice: "Samples were transferred successfully to standard_mx_tube #{Tube.last.human_barcode} ")
    end

    context 'when stock_mx_tube_required is true' do
      let(:stock_mx_tube_required) { true }

      it 'creates stock and standard mx tube' do
        expect(pooling.execute).to be true
        expect(pooling.stock_mx_tube.aliquots.count).to eq 5
        expect(pooling.standard_mx_tube.aliquots.count).to eq 5
        expect(pooling.message).to eq(notice: "Samples were transferred successfully to standard_mx_tube #{Tube.last.human_barcode} and stock_mx_tube #{Tube.last(2).first.human_barcode} ")
      end
    end

    context 'when a barcode printer is provided' do
      let(:barcode_printer) { create :barcode_printer }
      let(:barcode_printer_option) { barcode_printer.name }

      it 'executes print_job' do
        allow(LabelPrinter::PmbClient).to receive(:get_label_template_by_name).and_return('data' => [{ 'id' => 15 }])
        expect(RestClient).to receive(:post)
        expect(pooling.execute).to be true
        expect(pooling.print_job_required?).to be true
        expect(pooling.message).to eq(notice: "Samples were transferred successfully to standard_mx_tube #{Tube.last.human_barcode} Your 1 label(s) have been sent to printer #{barcode_printer.name}")
      end

      it 'returns correct message if something is wrong with pmb' do
        expect(RestClient).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(pooling.execute).to be true
        expect(pooling.message).to eq(error: 'Printmybarcode service is down', notice: "Samples were transferred successfully to standard_mx_tube #{Tube.last.human_barcode} ")
      end
    end
  end
end
