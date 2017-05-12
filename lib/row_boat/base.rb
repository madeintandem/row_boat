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

      import_results.each_with_object(invalid_records: [], total_inserted: 0, inserted_ids: []) do |import_result, total_results|
        total_results[:invalid_records] += import_result.failed_instances
        total_results[:total_inserted] += import_result.num_inserts
        total_results[:inserted_ids] += import_result.ids
      end
    end

    def import_into
      raise NotImplementedError, not_implemented_error_message(__method__)
    end

    def column_mapping
      raise NotImplementedError, not_implemented_error_message(__method__)
    end

    def preprocess_row(row)
      row
    end

    def import_rows(rows)
      import_options = ::RowBoat::Helpers.extract_import_options(merged_options)
      preprocessed_rows = rows.map { |row| preprocess_row(row) }
      import_into.import(preprocessed_rows, import_options)
    end

    def options
      {}
    end

    def default_options
      {
        chunk_size: 500,
        key_mapping: column_mapping,
        recursive: true,
        remove_unmapped_keys: true,
        validate: true,
        wrap_in_transaction: true
      }
    end

    def merged_options
      default_options.merge(options)
    end

    private

    def not_implemented_error_message(method_name)
      "Subclasses of #{self.class.name} must implement `#{method_name}`"
    end

    def parse_rows(&block)
      csv_options = ::RowBoat::Helpers.extract_csv_options(merged_options)
      ::SmarterCSV.process(csv_source, csv_options, &block)
    end

    def transaction_if_needed(&block)
      merged_options[:wrap_in_transaction] ? import_into.transaction(&block) : yield
    end
  end
end
