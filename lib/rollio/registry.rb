require 'forwardable'
require 'dice' # from dice_parser

module Rollio
  # Responsible for registering random tables and exposing a means of rolling on those tables.
  class Registry
    # @api private
    # @example
    # document = [{
    #   key: '1-a',
    #   roll: '2d6',
    #   entries: [
    #     { range: [2,3,4,5,6], roll_on: '1-b' },
    #     { range: [7], result: 'Yolo' },
    #     { range: [8,9,10,11,12], inner_table: {
    #         roll: '1d4',
    #         entries: [
    #           { range: [1,2,3], result: 'Yes' },
    #           { range: [4], result: 'No' }
    #         ]
    #       }
    #     }
    #   },{
    #     key: '1-b',
    #     roll: '1d6',
    #     entries: [
    #       { range: [1,2,3,4,5,6], result: 'sub-table' }
    #     ]
    #   }
    # ]
    # registry = Rollio::Registry.load(document)
    #
    # @example
    #   registry = Rollio::Registry.load do
    #     table('1') do
    #       roll('1d5')
    #       entry(1, 'Yes!')
    #       entry(2..5, 'No!')
    #     end
    #   end
    # @return [Rollio::Registry, #roll_on]
    # @todo Add document schema and validation
    # @todo Expose #load method to allow additional loading outside of initialization
    def self.load(document = nil, context = self, &block)
      if document
        Registry.new do |registry|
          document.each do |data|
            context.load_a_table(registry: registry, data: data, context: context)
          end
        end
      else
        Registry.new(&block)
      end
    end

    # @api private
    def self.load_a_table(registry:, data:, context:, key: nil)
      key ||= data.fetch(:key)
      label = data.fetch(:label, key)
      table = registry.table(key, label: label)
      table.roll(data.fetch(:roll))
      data.fetch(:entries).each do |table_entry|
        range = table_entry.fetch(:range)
        if table_entry.key?(:roll_on)
          table.entry(range, roll_on: table_entry.fetch(:roll_on))
        elsif table_entry.key?(:result)
          table.entry(range, table_entry.fetch(:result))
        elsif table_entry.key?(:inner_table)
          inner_table = table_entry.fetch(:inner_table)
          entry = table.entry(range, inner_table: true)
          Registry.load_a_table(registry: registry, data: inner_table, context: context, key: entry.key)
        end
      end
    end

    attr_reader :table_set
    def initialize(&block)
      @table_set = TableSet.new(registry: self)
      instance_exec(self, &block) if block_given?
    end

    # @api private
    # @param key [String] The key of the table you want to roll on
    # @see Registry::Table#key for details
    # @todo Consider adding a modifier (eg. `roll_on(key, with: -2)`)
    def roll_on(key)
      @table_set.roll_on(key)
    end

    def table(*args, &block)
      @table_set.add(*args, &block)
    end

    extend Forwardable
    def_delegator :table_set, :render

    class TableSet
      extend Forwardable

      def initialize(registry:)
        @registry = registry
        @tables = {}
      end

      private

      attr_reader :tables, :registry

      public

      def roll_on(table_name)
        table = @tables.fetch(table_name)
        table.roll!
      end

      def add(key, label: key, &block)
        @tables[key] = Table.new(table_set: self, key: key, label: label, &block)
      end

      def render(debug: false)
        puts "Table Set { object_id: #{object_id} }\n" if debug
        @tables.sort { |a,b| a[0] <=> b[0] }.each do |key, table|
          table.render
        end
        nil
      end
    end
    private_constant :TableSet

    class Table
      attr_reader :key, :table_set, :label
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
        @roller.render
        @range_set.render
      end

      def roll!
        roll = @roller.roll!
        @range_set.resolve(roll: roll)
      end

      def roll(text)
        @roller = Roller.new(text)
      end

      def entry(range, result = nil, roll_on: nil, inner_table: nil, &inner_table_config)
        @range_set.add(table: self, range: range, result: result, roll_on: roll_on, inner_table: inner_table, inner_table_config: inner_table_config)
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
        def self.new(table:, range:, result:, roll_on:, inner_table:, inner_table_config:)
          if result
            Result.new(table: table, range: range, result: result)
          elsif roll_on
            RollOn.new(table: table, range: range, roll_on: roll_on)
          elsif inner_table
            InnerRollOn.new(table: table, range: range)
          elsif inner_table_config
            InnerTable.new(table: table, range: range, inner_table: inner_table_config)
          else
            raise "Hello"
          end
        end

        class Base
          attr_reader :table, :range
          def initialize(table:, range:)
            @table = table
            self.range = range
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
            @result
          end
        end
        private_constant :Result

        class RollOn < Base
          def initialize(roll_on:, **kwargs)
            super(**kwargs)
            @roll_on = roll_on
          end

          def roll!
            table_set.roll_on(@roll_on)
          end

          def result
            "Roll on #{@roll_on}"
          end
        end
        private_constant :RollOn

        class InnerRollOn < Base
          def roll!
            table_set.roll_on(key)
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
            table_set.roll_on(key)
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
end
