module Rollio
  module Range
    def self.new(table:, range:, result:, roll_on: nil, inner_table: nil, inner_table_config: nil, times: 1, with: nil)
      if result
        Result.new(table: table, range: range, result: result, times: times)
      elsif roll_on
        RollOn.new(table: table, range: range, roll_on: roll_on, times: times, with: with)
      elsif inner_table
        InnerRollOn.new(table: table, range: range, times: times)
      elsif inner_table_config
        InnerTable.new(table: table, range: range, inner_table: inner_table_config, times: times)
      else
        raise "Hello"
      end
    end

    class Base
      attr_reader :table, :range, :times
      def initialize(table:, range:, times:, **kwargs)
        @table = table
        self.range = range
        @times = times
      end

      def key
        "#{table.key} (Sub #{range})"
      end

      extend Comparable
      def <=>(other)
        range.first <=> other.range.first
      end

      def render
        if range.first == range.last
          puts "#{range.first}\t#{result}"
        else
          puts "#{range.first}-#{range.last}\t#{result}"
        end
      end

      def result
        raise NotImplementedError
      end

      extend Forwardable
      def_delegator :table, :table_set

      def include?(value)
        if @range.respond_to?(:include?)
          @range.include?(value)
        else
          @range == value
        end
      end

      def range=(input)
        @range = Array(input)
      end
    end
    private_constant :Base

    class Result < Base
      attr_reader :result
      def initialize(result:, **kwargs)
        super(**kwargs)
        @result = result
      end

      def roll!
        [@result]
      end
    end
    private_constant :Result

    class RollOn < Base
      attr_reader :with
      def initialize(roll_on:, **kwargs)
        super(**kwargs)
        @roll_on = roll_on
        @with = kwargs[:with]
      end

      def roll!
        (1..times).map { table_set.roll_on(@roll_on, with: with) }
      end

      def result
        "Roll on #{@roll_on}"
      end
    end
    private_constant :RollOn

    class InnerRollOn < Base
      def roll!
        (1..times).map { table_set.roll_on(key) }
      end

      def result
        "Roll on #{key}"
      end
    end

    class InnerTable < Base
      def initialize(inner_table:, **kwargs)
        super(**kwargs)
        @table.table_set.add(key, &inner_table)
      end

      def roll!
        (1..times).map { table_set.roll_on(key) }
      end

      def result
        "Roll on #{key}"
      end
    end
    private_constant :InnerTable
  end
  private_constant :Range
end
