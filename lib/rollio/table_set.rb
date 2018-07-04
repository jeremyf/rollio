require 'rollio/table'

module Rollio
  # The data store for all of the registered tables
  class TableSet

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

    def render(table: nil, debug: false)
      puts "Table Set { object_id: #{object_id} }\n" if debug
      if table
        tables.fetch(table).render
      else
        tables.sort { |a,b| a[0] <=> b[0] }.each do |key, table|
          table.render
        end
      end
      nil
    end
  end
  private_constant :TableSet
end
