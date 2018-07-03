require 'forwardable'
require 'dice' # from dice_parser

module Rollio
  # Responsible for registering random tables and exposing a means of rolling on those tables.
  class Registry
    # @api public
    def initialize(&block)
      self.table_set = TableSet.new(registry: self)
      instance_exec(self, &block) if block_given?
    end

    attr_accessor :table_set
    private :table_set=

    # @api private
    # @param key [String] The key of the table you want to roll on
    # @see Registry::Table#key for details
    # @todo Consider adding a modifier (eg. `roll_on(key, with: -2)`)
    def roll_on(key, **kwargs)
      table_set.roll_on(key, **kwargs)
    end

    # @api private
    # The exposed method for adding a table to the registry
    def table(*args, &block)
      table_set.add(*args, &block)
    end

    extend Forwardable
    def_delegator :table_set, :render
    def_delegator :table_set, :table_names

    # The data store for all of the registered tables
    class TableSet
      extend Forwardable

      def initialize(registry:)
        @registry = registry
        @tables = {}
      end

      private

      attr_reader :tables, :registry

      public

      def table_names
        tables.keys.sort
      end

      def roll_on(table_name, **kwargs)
        table = tables.fetch(table_name)
        table.roll!(**kwargs)
      end

      def add(key, label: key, &block)
        tables[key] = Table.new(table_set: self, key: key, label: label, &block)
      end

      def render(debug: false)
        puts "Table Set { object_id: #{object_id} }\n" if debug
        tables.sort { |a,b| a[0] <=> b[0] }.each do |key, table|
          table.render
        end
        nil
      end
    end
    private_constant :TableSet

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

      protected

        class Roller
          def initialize(text)
            @text = text
          end

          def roll!
            Dice.roll(@text)
          end

          def render
            puts "#{@text}\tResult"
          end
        end
        private_constant :Roller

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
    private_constant :Table
  end
  private_constant :Registry
end
