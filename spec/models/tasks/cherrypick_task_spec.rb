require 'rails_helper'

RSpec.describe CherrypickTask, type: :model do
  let!(:plate) { create :plate_with_untagged_wells, sample_count: 4 }
  let(:control_plate) { create :control_plate, sample_count: 2 }
  let(:requests) { plate.wells.in_column_major_order.map { |w| create(:cherrypick_request, asset: w) }.flatten }
  let(:template) { create(:plate_template, size: 6) }
  let(:robot) { double('robot', max_beds: 2) }
  let(:purpose) { create :purpose }
  let(:batch) { double('batch', id: 1235, requests: requests) }
  let(:submission) { create :submission }
  let(:request_type) { create :request_type }

  def pick_without_request_id(plates)
    plates.map { |plate| plate.map { |_id, barcode, pos| [barcode, pos] } }
  end

  describe '#pick_new_plate' do
    context 'with control plate' do
      before do
        requests.first.update(submission: submission, request_type: request_type)
        allow(requests.first).to receive(:batch).and_return(batch)
      end

      context 'when controls and wells fit in one plate' do
        let(:destinations) do
          [[
            [control_plate.human_barcode, 'B1'],
            [plate.human_barcode, 'A1'],
            [plate.human_barcode, 'B1'],
            [plate.human_barcode, 'C1'],
            [plate.human_barcode, 'D1'],
            [control_plate.human_barcode, 'A1']
          ]]
        end

        it 'generates one plate' do
          pick = described_class.new.pick_new_plate(requests, template, robot, purpose, control_plate)
          expect(pick_without_request_id(pick[0])).to eq(destinations)
        end
      end

      context 'when control positions clashes with templates' do
        let(:destinations) do
          [
            [
              [control_plate.human_barcode, 'B1'],
              [plate.human_barcode, 'A1'],
              [plate.human_barcode, 'B1'],
              [plate.human_barcode, 'C1'],
              [control_plate.human_barcode, 'A1'],
              ['---', '']
            ],
            [
              [control_plate.human_barcode, 'A1'],
              [control_plate.human_barcode, 'B1'],
              [plate.human_barcode, 'D1'],
              ['Empty', ''],
              ['Empty', ''],
              ['---', '']
            ]
          ]
        end

        before do
          template.wells.create!
          template.wells.first.update(map_id: 6)
        end

        it 'places controls in a different position' do
          pick = described_class.new.pick_new_plate(requests, template, robot, purpose, control_plate)
          expect(pick_without_request_id(pick[0])).to eq(destinations)
        end
      end
    end
  end

  describe '#pick_onto_partial_plate' do
    let!(:partial_plate) { create :plate, size: 6 }

    before do
      partial_plate.wells.create!
      partial_plate.wells.first.update(map_id: 6)
    end

    context 'with controls' do
      before do
        requests.first.update(submission: submission, request_type: request_type)
        allow(requests.first).to receive(:batch).and_return(batch)
      end

      context 'when controls and wells fit in one plate' do
        let!(:plate) { create :plate_with_untagged_wells, sample_count: 2 }
        let(:destinations) do
          [[
            [control_plate.human_barcode, 'B1'],
            [plate.human_barcode, 'A1'],
            [plate.human_barcode, 'B1'],
            [control_plate.human_barcode, 'A1'],
            ['Empty', ''],
            ['---', '']
          ]]
        end

        it 'generates one plate' do
          pick = described_class.new.pick_onto_partial_plate(requests, template, robot, partial_plate, control_plate)
          expect(pick_without_request_id(pick[0])).to eq(destinations)
        end
      end

      context 'when control positions clashes with partial' do
        let!(:plate) { create :plate_with_untagged_wells, sample_count: 4 }
        let(:destinations) do
          [
            [
              [control_plate.human_barcode, 'B1'],
              [plate.human_barcode, 'A1'],
              [plate.human_barcode, 'B1'],
              [plate.human_barcode, 'C1'],
              [control_plate.human_barcode, 'A1'],
              ['---', '']
            ],
            [
              [control_plate.human_barcode, 'A1'],
              [control_plate.human_barcode, 'B1'],
              [plate.human_barcode, 'D1'],
              ['Empty', ''],
              ['Empty', ''],
              ['Empty', '']
            ]
          ]
        end

        it 'places controls in a different position' do
          pick = described_class.new.pick_onto_partial_plate(requests, template, robot, partial_plate, control_plate)
          expect(pick_without_request_id(pick[0])).to eq(destinations)
        end
      end
    end
  end

  describe '#control_positions' do
    it 'calculates the positions for the control wells' do
      # Test batch id 0, plate 0 to 4, 5 free wells, 2 control wells
      expect(described_class.new.control_positions(0, 0, 5, 2)).to eq([0, 1])
      expect(described_class.new.control_positions(0, 1, 5, 2)).to eq([1, 2])
      expect(described_class.new.control_positions(0, 2, 5, 2)).to eq([2, 3])
      expect(described_class.new.control_positions(0, 3, 5, 2)).to eq([3, 4])
      expect(described_class.new.control_positions(0, 4, 5, 2)).to eq([4, 0])
    end

    it 'can allocate all controls in all wells' do
      # Test batch id 0, plate 0, 2 free wells, 2 control wells
      expect(described_class.new.control_positions(0, 0, 2, 2)).to eq([0, 1])
    end

    it 'fails when you try to put more controls than free wells' do
      # Test batch id 0, plate 0, 2 free wells, 3 control wells, so they dont fit
      expect do
        described_class.new.control_positions(0, 0, 2, 3)
      end.to raise_error(ZeroDivisionError)
    end

    it 'does not clash with consecutive batches (1)' do
      # Test batch id 12345, plate 0 to 2, 100 free wells, 3 control wells
      expect(described_class.new.control_positions(12345, 0, 100, 3)).to eq([45, 24, 1])
      expect(described_class.new.control_positions(12345, 1, 100, 3)).to eq([46, 25, 2])
      expect(described_class.new.control_positions(12345, 2, 100, 3)).to eq([47, 26, 3])
    end

    it 'does not clash with consecutive batches (2)' do
      # Test batch id 12346, plate 0 to 2, 100 free wells, 3 control wells
      expect(described_class.new.control_positions(12345 + 1, 0, 100, 3)).to eq([46, 24, 1])
      expect(described_class.new.control_positions(12345 + 1, 1, 100, 3)).to eq([47, 25, 2])
      expect(described_class.new.control_positions(12345 + 1, 2, 100, 3)).to eq([48, 26, 3])
    end

    it 'does not clash with consecutive batches (3)' do
      # Test batch id 12445, plate 0 to 2, 100 free wells, 3 control wells
      expect(described_class.new.control_positions(12345 + 100, 0, 100, 3)).to eq([45, 25, 1])
      expect(described_class.new.control_positions(12345 + 100, 1, 100, 3)).to eq([46, 26, 2])
      expect(described_class.new.control_positions(12345 + 100, 2, 100, 3)).to eq([47, 27, 3])
    end

    it 'does not clash with consecutive batches (4)' do
      # Test batch id 12545, plate 0 to 2, 100 free wells, 3 control wells
      expect(described_class.new.control_positions(12345 + 200, 0, 100, 3)).to eq([45, 26, 1])
      expect(described_class.new.control_positions(12345 + 200, 1, 100, 3)).to eq([46, 27, 2])
      expect(described_class.new.control_positions(12345 + 200, 2, 100, 3)).to eq([47, 28, 3])
    end

    it 'also works with big batch id and small wells' do
      # Test batch id 12545, plate 0 to 4, 3 free wells, 1 control wells
      expect(described_class.new.control_positions(12345, 0, 3, 1)).to eq([0])
      expect(described_class.new.control_positions(12345, 1, 3, 1)).to eq([1])
      expect(described_class.new.control_positions(12345, 2, 3, 1)).to eq([2])
      expect(described_class.new.control_positions(12345, 3, 3, 1)).to eq([0])
      expect(described_class.new.control_positions(12345, 4, 3, 1)).to eq([1])
    end
  end
end
