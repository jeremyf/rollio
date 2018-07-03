require 'dry-validation'
require 'rollio/schemas/entry_schema'
module Rollio
  module Schemas
    TableSchema = Dry::Validation.Schema do
      required(:key).filled(:str?)
      required(:roll).filled(:str?)
      required(:entries).each do
        schema(EntrySchema)
      end
    end
  end
end
