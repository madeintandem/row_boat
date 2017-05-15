# frozen_string_literal: true

require "active_record"
require "activerecord-import"
require "smarter_csv"

module RowBoat
  class Base
    attr_reader :csv_source

    class << self
      # Imports database records from the given CSV-like object.
      #
      # @abstract Feel free to override this if you need additional arguments
      #   to process your CSV. Just make sure it matches the method signature of {#initialize}.
      #   (If you override {#initialize} then match that method signature)
      #
      # @overload import(csv_source)
      #   @param csv_source [String, #read] a CSV-like object that SmarterCSV can read.
      # @return [Hash] a hash with +:invalid_records+, +:total_inserted+ and +:inserted_ids+.
      # @see https://github.com/tilo/smarter_csv#documentation SmarterCSV Docs
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

      process_import_results(import_results).tap do |total_results|
        handle_failed_rows(total_results[:invalid_records])
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
      preprocessed_rows = preprocess_rows(rows)
      import_into.import(preprocessed_rows, import_options)
    end

    def preprocess_rows(rows)
      rows.each_with_object([]) do |row, preprocessed_rows|
        preprocessed_row = preprocess_row(row)
        preprocessed_rows << preprocessed_row unless preprocessed_row.nil?
      end
    end

    def options
      {}
    end

    # @api private
    def default_options
      {
        chunk_size: 500,
        key_mapping: column_mapping,
        recursive: true,
        remove_unmapped_keys: true,
        validate: true,
        value_converters: csv_value_converters,
        wrap_in_transaction: true
      }
    end

    # @api private
    def merged_options
      default_options.merge(options)
    end

    def handle_failed_row(row)
      row
    end

    def handle_failed_rows(rows)
      rows.each { |row| handle_failed_row(row) }
    end

    def value_converters
      {}
    end

    # @api private
    def csv_value_converters
      value_converters.each_with_object({}) do |(key, potential_converter), converters_hash|
        case potential_converter
        when Proc
          converters_hash[key] = ::RowBoat::ValueConverter.new(&potential_converter)
        when Symbol
          converters_hash[key] = ::RowBoat::ValueConverter.new { |value| public_send(potential_converter, value) }
        when nil
          next
        else
          converters_hash[key] = potential_converter
        end
      end
    end

    private

    # @api private
    # @private
    def not_implemented_error_message(method_name)
      "Subclasses of #{self.class.name} must implement `#{method_name}`"
    end

    # @api private
    # @private
    def parse_rows(&block)
      csv_options = ::RowBoat::Helpers.extract_csv_options(merged_options)
      ::SmarterCSV.process(csv_source, csv_options, &block)
    end

    # @api private
    # @private
    def transaction_if_needed(&block)
      merged_options[:wrap_in_transaction] ? import_into.transaction(&block) : yield
    end

    # @api private
    # @private
    def process_import_results(import_results)
      import_results.each_with_object(
        invalid_records: [],
        total_inserted: 0,
        inserted_ids: []
      ) do |import_result, total_results|
        total_results[:invalid_records] += import_result.failed_instances
        total_results[:total_inserted] += import_result.num_inserts
        total_results[:inserted_ids] += import_result.ids
      end
    end
  end
end
