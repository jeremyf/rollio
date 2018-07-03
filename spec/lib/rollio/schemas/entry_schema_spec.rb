require 'spec_helper'
require 'rollio/schemas/entry_schema'

module Rollio
  module Schemas
    RSpec.describe 'EntrySchema' do
      let(:described_class) { EntrySchema }
      describe 'valid scenarios' do
        [
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
        ].each_with_index do |entry, index|
          it "validates scenario ##{index+1} (#{entry.inspect})" do
            expect(described_class.call(entry).messages).to be_empty
          end
        end
      end

      describe 'invalid scenarios' do
        it "invalidates scenario #1" do
          expect(described_class.call(range: [1,2]).messages).not_to be_empty
        end
      end
    end
  end
end
