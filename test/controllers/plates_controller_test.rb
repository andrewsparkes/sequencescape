# frozen_string_literal: true

require 'test_helper'

class PlatesControllerTest < ActionController::TestCase
  context 'Plate' do
    setup do
      @prefix = 'DN'
      @controller = PlatesController.new
      @request    = ActionController::TestRequest.create(@controller)

      @pico_purposes = create_list :pico_assay_purpose, 2
      @working_dilution = create_list :working_dilution_plate_purpose, 1

      @pico_assay_plate_creator = FactoryBot.create :plate_creator, plate_purposes: @pico_purposes
      @dilution_plates_creator = FactoryBot.create :plate_creator, plate_purposes: @working_dilution

      @barcode_printer = create :barcode_printer

      PlateBarcode.stubs(:create).returns(
        stub(barcode: 1234567),
        stub(barcode: 1234568),
        stub(barcode: 1234569),
        stub(barcode: 1234570),
        stub(barcode: 1234571),
        stub(barcode: 1234572)
      )
      LabelPrinter::PmbClient.stubs(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])
      LabelPrinter::PmbClient.stubs(:print).returns(200)
    end

    context 'with a logged in user' do
      setup do
        @user = FactoryBot.create :user, barcode: 'ID100I', swipecard_code: '1234567'
        @user.is_administrator
        session[:user] = @user.id

        @parent_plate = FactoryBot.create :plate, barcode: '5678'
        @parent_plate2 = FactoryBot.create :plate, barcode: '1234'
        @parent_plate3 = FactoryBot.create :plate, barcode: '987'
      end

      context '#new' do
        setup do
          get :new
        end
        should respond_with :success
        should_not set_flash
      end

      context '#create' do
        context 'with no source plates' do
          setup do
            @plate_count = Plate.count
            post :create, params: { plates: { creator_id: @dilution_plates_creator.id, barcode_printer: @barcode_printer.id, user_barcode: '1234567' } }
          end

          should 'change Plate.count by 1' do
            assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
          end
          should respond_with :redirect
          should set_flash.to(/Created/)
        end

        context 'Create a Plate' do
          context 'with one source plate' do
            setup do
              @well = create :well
              @parent_plate.wells << [@well]
              @parent_raw_barcode = @parent_plate.machine_barcode
            end

            context "and we don't select any dilution factor" do
              context "when we don't have a parent" do
                setup do
                  @plate_count = Plate.count
                  post :create, params: { plates: { creator_id: @dilution_plates_creator.id, barcode_printer: @barcode_printer.id,
                                                    source_plates: '', user_barcode: '2470000100730' } }
                end

                should 'change Plate.count by 1' do
                  assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
                end

                should 'set the dilution factor to default (1.0)' do
                  assert_equal 1.0, Plate.last.dilution_factor
                end
              end

              context "when the parent doesn't have a dilution factor" do
                setup do
                  @plate_count = Plate.count
                  post :create, params: { plates: { creator_id: @dilution_plates_creator.id, barcode_printer: @barcode_printer.id,
                                                    source_plates: @parent_raw_barcode.to_s, user_barcode: '2470000100730' } }
                end

                should 'change Plate.count by 1' do
                  assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
                end

                should 'set the dilution factor to default (1.0)' do
                  assert_equal 1.0, @parent_plate.children.first.dilution_factor
                end
              end

              context 'when the parent plate has a dilution factor of 3.53' do
                setup do
                  @parent_plate.dilution_factor = 3.53
                  @parent_plate.save!
                  @plate_count = Plate.count
                  post :create, params: { plates: { creator_id: @dilution_plates_creator.id, barcode_printer: @barcode_printer.id,
                                                    source_plates: @parent_raw_barcode.to_s, user_barcode: '2470000100730' } }
                end

                should 'change Plate.count by 1' do
                  assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
                end

                should 'set the dilution factor to 3.53' do
                  assert_equal 3.53, @parent_plate.children.first.dilution_factor
                end
              end

              context 'when we have 2 parents' do
                setup do
                  @well2 = create :well
                  @parent_plate2.wells << [@well2]
                  @parent2_raw_barcode = @parent_plate2.machine_barcode
                end

                context 'and first parent has a dilution factor of 3.53, and second parent with 4.56' do
                  setup do
                    @parent_plate.dilution_factor = 3.53
                    @parent_plate.save!

                    @parent_plate2.dilution_factor = 4.56
                    @parent_plate2.save!
                  end

                  context "and I don't select any dilution factor" do
                    setup do
                      @plate_count = Plate.count
                      post :create, params: { plates: { creator_id: @dilution_plates_creator.id, barcode_printer: @barcode_printer.id,
                                                        source_plates: "#{@parent_raw_barcode},#{@parent2_raw_barcode}", user_barcode: '2470000100730' } }
                    end

                    should 'change Plate.count by 2' do
                      assert_equal 2, Plate.count - @plate_count, 'Expected Plate.count to change by 2'
                    end

                    should 'set the dilution factor of each children to 3.53 and 4.56' do
                      assert_equal 3.53, @parent_plate.children.first.dilution_factor
                      assert_equal 4.56, @parent_plate2.children.first.dilution_factor
                    end
                  end

                  context 'and I select a dilution factor of 2.0' do
                    setup do
                      @plate_count = Plate.count
                      post :create, params: { plates: { creator_id: @dilution_plates_creator.id, barcode_printer: @barcode_printer.id,
                                                        source_plates: "#{@parent_raw_barcode},#{@parent2_raw_barcode}", user_barcode: '2470000100730',
                                                        dilution_factor: 2.0 } }
                    end

                    should 'change Plate.count by 2' do
                      assert_equal 2, Plate.count - @plate_count, 'Expected Plate.count to change by 2'
                    end

                    should 'set the dilution factor of each children to 7.06 and 9.12' do
                      # This test showed different behaviour between MRI and jruby
                      # In particular, the dilution factors are represented as BigDecimals
                      # and while MRI reports inequality with the float, Jruby declares them equal.
                      # This isn't actually true for ALL floats and their big decimal 'equivalent'
                      # so presumably its due to the accuracy of the float.
                      assert_equal 7.06, @parent_plate.children.first.dilution_factor.to_f
                      assert_equal 9.12, @parent_plate2.children.first.dilution_factor.to_f
                    end
                  end
                end
              end
            end

            context 'and we select a dilution factor of 12.0' do
              context "when we don't have a parent" do
                setup do
                  @plate_count = Plate.count
                  post :create, params: { plates: { creator_id: @dilution_plates_creator.id, barcode_printer: @barcode_printer.id,
                                                    source_plates: '', user_barcode: '2470000100730',
                                                    dilution_factor: 12.0 } }
                end

                should 'change Plate.count by 1' do
                  assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
                end

                should 'set the dilution factor to 12.0' do
                  assert_equal 12.0, Plate.last.dilution_factor
                end
              end
              context "when the parent doesn't have a dilution factor" do
                setup do
                  @plate_count = Plate.count
                  post :create, params: { plates: { creator_id: @dilution_plates_creator.id, barcode_printer: @barcode_printer.id,
                                                    source_plates: @parent_raw_barcode.to_s, user_barcode: '2470000100730',
                                                    dilution_factor: 12.0 } }
                end

                should 'change Plate.count by 1' do
                  assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
                end

                should 'set the dilution factor to 12.0' do
                  assert_equal 12.0, @parent_plate.children.first.dilution_factor
                end
              end

              context 'when the parent plate has a dilution factor of 4.0' do
                setup do
                  @plate_count = Plate.count
                  @parent_plate.dilution_factor = 4
                  @parent_plate.save!
                  post :create, params: { plates: { creator_id: @dilution_plates_creator.id, barcode_printer: @barcode_printer.id,
                                                    source_plates: @parent_raw_barcode.to_s, user_barcode: '2470000100730',
                                                    dilution_factor: 12.0 } }
                end

                should 'change Plate.count by 1' do
                  assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
                end

                should 'sets the dilution factor to 48.0 (parent=4*child=12)' do
                  assert_equal 48.0, @parent_plate.children.first.dilution_factor
                end
              end
            end
          end
        end

        context 'Create Pico Assay Plates' do
          context 'with one source plate' do
            setup do
              @parent_raw_barcode = @parent_plate.machine_barcode
            end

            context 'without a dilution factor' do
              setup do
                @picoassayplate_count = PicoAssayPlate.count
                post :create, params: { plates: { creator_id: @pico_assay_plate_creator.id, barcode_printer: @barcode_printer.id,
                                                  source_plates: @parent_raw_barcode.to_s, user_barcode: '2470000100730' } }
              end

              should 'change PicoAssayPlate.count by 2' do
                assert_equal 2, PicoAssayPlate.count - @picoassayplate_count, 'Expected PicoAssayPlate.count to change by 2'
              end

              should 'add a child to the parent plate' do
                assert Plate.find(@parent_plate.id).children.first.is_a?(Plate)
                assert_equal @pico_purposes.first, Plate.find(@parent_plate.id).children.first.plate_purpose
              end

              should respond_with :redirect

              should set_flash.to(/Created/)
            end

            context 'with a parent with dilution factor 4 and a specified dilution factor 12' do
              setup do
                @parent_plate.dilution_factor = 4
                @parent_plate.save!
                post :create, params: { plates: { creator_id: @pico_assay_plate_creator.id,
                                                  barcode_printer: @barcode_printer.id, source_plates: @parent_raw_barcode.to_s,
                                                  dilution_factor: 12.0,
                                                  user_barcode: '2470000100730' } }
              end

              should 'create all the pico assay plates with dilution factor 48' do
                childrens = Plate.find(@parent_plate.id).children
                assert_equal 48.0, childrens.first.dilution_factor
                assert_equal 1, childrens.map(&:dilution_factor).uniq.length
              end
            end
          end

          context 'with 3 source plates' do
            setup do
              @picoassayplate_count = PicoAssayPlate.count
              @parent_raw_barcode  = @parent_plate.machine_barcode
              @parent_raw_barcode2 = @parent_plate2.machine_barcode
              @parent_raw_barcode3 = @parent_plate3.machine_barcode
              post :create, params: { plates: { creator_id: @pico_assay_plate_creator.id, barcode_printer: @barcode_printer.id, source_plates: "#{@parent_raw_barcode}\n#{@parent_raw_barcode2}\t#{@parent_raw_barcode3}",
                                                user_barcode: '2470000100730' } }
            end

            should 'change PicoAssayPlate.count by 6' do
              assert_equal 6, PicoAssayPlate.count - @picoassayplate_count, 'Expected PicoAssayPlate.count to change by 6'
            end

            should 'have child plates' do
              [@parent_plate, @parent_plate2, @parent_plate3].each do |plate|
                assert Plate.find(plate.id).children.first.is_a?(Plate)
                assert_equal @pico_purposes.first, Plate.find(plate.id).children.first.plate_purpose
              end
            end
            should respond_with :redirect
            should set_flash.to(/Created/)
          end
        end
      end
    end
  end
end
