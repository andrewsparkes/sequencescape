# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PlatePurposeIO, type: :model do
  subject { create :plate_purpose }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'internal_id' => subject.id,
      'name' => subject.name
    }
  end

  it_behaves_like('an IO object')
end
