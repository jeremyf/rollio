require "rollio/version"
require "rollio/registry"
require 'json'
require 'hanami/utils/hash'

module Rollio
  # @api private
  # @example
  # document = [{
  #   key: '1-a',
  #   roll: '2d6',
  #   entries: [
  #     { range: [2,3,4,5,6], roll_on: '1-b', with: '1d3', times: 2},
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
  # @todo Does the guts of this logic make sense here?
  def self.load_a_table(registry: , data:, context: self, key: nil)
    key ||= data.fetch(:key)
    label = data.fetch(:label, key)
    table = registry.table(key, label: label)
    table.roll(data.fetch(:roll))
    data.fetch(:entries).each do |table_entry|
      range = table_entry.fetch(:range)
      if table_entry.key?(:roll_on)
        table.entry(range, **table_entry)
      elsif table_entry.key?(:result)
        table.entry(range, table_entry.fetch(:result))
      elsif table_entry.key?(:inner_table)
        inner_table = table_entry.fetch(:inner_table)
        entry = table.entry(range, inner_table: true)
        context.load_a_table(registry: registry, data: inner_table, context: context, key: entry.key)
      end
    end
  end
end
