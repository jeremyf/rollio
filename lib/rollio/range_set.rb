require 'rollio/range'
module Rollio
  class RangeSet
    def initialize(table:)
      @table = table
      @ranges = []
    end

    def render
      @ranges.sort.each do |range|
        range.render
      end
    end

    def resolve(roll:)
      @ranges.detect { |range| range.include?(roll) }.roll!
    end

    def add(range:, **kwargs)
      range_object = Range.new(range: range, **kwargs)
      @ranges << range_object
      range_object
    end
  end
  private_constant :RangeSet
end
