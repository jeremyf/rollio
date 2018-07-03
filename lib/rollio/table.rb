require 'rollio/roller'
require 'rollio/range_set'
module Rollio
  class Table
    attr_reader :key, :table_set, :label, :roller
    private :roller
    def initialize(table_set:, key:, label:, &block)
      @key = key
      @table_set = table_set
      @label = label
      @range_set = RangeSet.new(table: self)
      instance_exec(self, &block)  if block_given?
    end

    def render
      header = "Table: #{key}"
      header = "#{header} - #{label}" unless label == key
      puts header
      puts '-' * header.length
      roller.render
      @range_set.render
    end

    def roll!(with: roller)
      the_roller = with.is_a?(Roller) ? with : Roller.new(with)
      roll = the_roller.roll!
      @range_set.resolve(roll: roll)
    end

    def roll(text)
      @roller = Roller.new(text)
    end

    def entry(range, result = nil, **kwargs, &inner_table_config)
      @range_set.add(
        table: self,
        range: range,
        result: result,
        inner_table_config: inner_table_config,
        **kwargs
      )
    end
  end
  private_constant :Table
end
