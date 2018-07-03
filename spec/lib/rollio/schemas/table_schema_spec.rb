require 'spec_helper'
require 'rollio/schemas/table_schema'

module Rollio
  module Schemas
    RSpec.describe 'TableSchema' do
      let(:described_class) { TableSchema }
      let(:table) do
        {
          key: '1-a',
          roll: '2d6',
          entries: [
            { range: [2,3,4,5,6], roll_on: '1-b', with: '1d3', times: 2},
            { range: [7], result: 'Yolo' },
            { range: [8,9,10,11,12], inner_table: {
                roll: '1d4',
                entries: [
                  { range: [1,2,3], result: 'Yes' },
                  { range: [4], result: 'No' }
                ]
              }
            }
          ]
        }
      end

      it 'validates a table' do
        expect(described_class.call(table).messages).to be_empty
      end
    end
  end
end
