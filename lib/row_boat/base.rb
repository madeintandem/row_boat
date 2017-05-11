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
      import_results = []

      transaction_if_needed do
        parse_rows do |rows|
          import_results << import_rows(rows)
        end
      end

      { invalid_records: import_results.flat_map(&:failed_instances) }
    end

    def import_into
      raise NotImplementedError, not_implemented_error_message(__method__)
    end

    def column_mapping
      raise NotImplementedError, not_implemented_error_message(__method__)
    end

    def options
      {
        chunk_size: 500,
        key_mapping: column_mapping,
        remove_unmapped_keys: true,
        validate: true,
        wrap_in_transaction: true
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
      import_into.import(rows, import_options)
    end

    def transaction_if_needed(&block)
      options[:wrap_in_transaction] ? import_into.transaction(&block) : yield
    end
  end
end
