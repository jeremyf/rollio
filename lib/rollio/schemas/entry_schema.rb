require 'dry-validation'
module Rollio
  module Schemas
    EntrySchema = Dry::Validation.Schema do
      required(:range).each(:int?)
      optional(:result).maybe(:str?)
      optional(:roll_on).maybe(:str?)
      optional(:inner_table).schema do
        required(:roll).filled(:str?)
        required(:entries).each do
          schema do
            required(:range).each(:int?)
            optional(:result).maybe(:str?)
            optional(:roll_on).maybe(:str?)
          end
        end
      end

      rule :result_or_inner_table_or_rolled_on_is_required do
        value(:result).filled? ^ value(:roll_on).filled? ^ value(:inner_table).filled?
      end
    end
  end
end
