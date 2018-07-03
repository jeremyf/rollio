require 'forwardable'
require 'dice' # from dice_parser
require 'rollio/table_set'

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
  end
  private_constant :Registry
end
