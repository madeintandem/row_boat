# frozen_string_literal: true

require "active_record"
require "activerecord-import"
require "smarter_csv"

module RowBoat
  class Base
    attr_reader :csv_source

    class << self
      def import(*args, &block)
        new(*args, &block).import
      end
    end

    def initialize(csv_source)
      @csv_source = csv_source
    end

    def import
      transaction_if_needed do
        parse_rows { |rows| import_rows(rows) }
      end
    end

    def import_into
      raise NotImplementedError, not_implemented_error_message(__method__)
    end

    def column_mapping
      raise NotImplementedError, not_implemented_error_message(__method__)
    end

    def options
      {
        key_mapping: column_mapping,
        remove_unmapped_keys: true,
        wrap_in_transaction: true,
        chunk_size: 500
      }
    end

    private

    def not_implemented_error_message(method_name)
      "Subclasses of #{self.class.name} must implement `#{method_name}`"
    end

    def parse_rows(&block)
      csv_options = ::RowBoat::Helpers.extract_csv_options(options)
      ::SmarterCSV.process(csv_source, csv_options, &block)
    end

    def import_rows(rows)
      import_options = ::RowBoat::Helpers.extract_import_options(options)
      import_into.import!(rows, import_options)
    end

    def transaction_if_needed(&block)
      if options[:wrap_in_transaction]
        import_into.transaction(&block)
      else
        yield
      end
    end
  end
end
