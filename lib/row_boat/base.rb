# frozen_string_literal: true

require "active_record"
require "activerecord-import"
require "smarter_csv"

module RowBoat
  class Base
    InvalidColumnMapping = Class.new(StandardError)

    attr_reader :csv_source

    class << self
      # Imports database records from the given CSV-like object.
      #
      # @overload import(csv_source)
      #   @param csv_source [String, #read] a CSV-like object that SmarterCSV can read.
      #
      # @return [Hash] a hash with +:invalid_records+, +:total_inserted+, +:inserted_ids+, and +:skipped_rows+.
      #
      # @see https://github.com/tilo/smarter_csv#documentation SmarterCSV Docs
      def import(*args, &block)
        new(*args, &block).import
      end
    end

    # Makes a new instance with the given +csv_source+.
    #
    # @abstract Override this method if you need additional arguments to process your CSV (like defaults).
    #
    # @example
    #   def initialize(csv_source, default_name)
    #     super(csv_source)
    #     @default_name = default_name
    #   end
    def initialize(csv_source)
      @csv_source = csv_source
    end

    # Parses the csv and inserts/updates the database. You probably won't call this method directly,
    # instead you would call {RowBoat::Base.import}.
    #
    # @return [Hash] a hash with +:invalid_records+, +:total_inserted+, +:inserted_ids+, and +:skipped_rows+.
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

    # Override with the ActiveRecord class that the CSV should be imported into.
    #
    # @abstract
    #
    # @note You must implement this method.
    #
    # @example
    #   def import_into
    #     Product
    #   end
    def import_into
      raise NotImplementedError, not_implemented_error_message(__method__)
    end

    # Override with a hash that maps CSV column names to their preferred names.
    #   Oftentimes these are the names of the attributes on the model class from {#import_into}.
    #
    # @abstract
    #
    # @note You must implement this method.
    #
    # @example
    #   def column_mapping
    #     {
    #       prdct_name: :name,
    #       price: :price,
    #       sl_exp: :sale_expires_at
    #     }
    #   end
    #
    # @see #import_into
    def column_mapping
      raise NotImplementedError, not_implemented_error_message(__method__)
    end

    # Override this method if you need to do some work on the row before the record is
    #   inserted/updated or want to skip the row in the import. Simply return +nil+ to skip the row.
    #
    # @abstract
    #
    # @note If you only need to manipulate one attribute (ie parse a date from a string, etc), then
    #   you should probably use {#value_converters}
    #
    # @return [Hash,NilClass] a hash of attributes, +nil+, or even and instance of the class returned
    #   in {#import_into}.
    #
    # @see #import_into
    def preprocess_row(row)
      row
    end

    # @api private
    def import_rows(rows)
      import_options = ::RowBoat::Helpers.extract_import_options(merged_options)
      preprocessed_rows = preprocess_rows(rows)
      import_into.import(preprocessed_rows, import_options)
    end

    # Override this method if you need to do something with a chunk of rows.
    #
    # @abstract
    #
    # @note If you want to filter out a row, you can just return +nil+ from {#preprocess_row}.
    #
    # @see #preprocess_row
    def preprocess_rows(rows)
      rows.each_with_object([]) do |row, preprocessed_rows|
        increment_row_number
        preprocessed_row = preprocess_row(row)
        preprocessed_row ? preprocessed_rows << preprocessed_row : add_skipped_row(row)
      end
    end

    # Override this method to specify CSV parsing and importing options.
    #   All SmarterCSV and activerecord-import options can be listed here along with
    #   +:wrap_in_transaction+. The defaults provided by RowBoat can be found in {#default_options}
    #
    # @abstract
    #
    # @note If you want to use the +:value_converters+ option provided by SmarterCSV
    #   just override {#value_converters}.
    #
    # @return [Hash] a hash of configuration options.
    #
    # @see https://github.com/tilo/smarter_csv#documentation SmarterCSV docs
    # @see https://github.com/zdennis/activerecord-import/wiki activerecord-import docs
    # @see #value_converters
    def options
      {}
    end

    # Default options provided by RowBoat for CSV parsing and importing.
    #
    # @note Do not override.
    #
    # @return [Hash] a hash of configuration options.
    #
    # @api private
    def default_options
      {
        chunk_size: 500,
        recursive: false,
        validate: true,
        value_converters: csv_value_converters,
        wrap_in_transaction: true
      }.merge(column_mapping_options)
    end

    # @api private
    def merged_options
      default_options.merge(options)
    end

    # Override this method to do some work with a row that has failed to import.
    #
    # @abstract
    #
    # @note +row+ here is actually an instance of the class returned in {#import_into}
    #
    # @see #import_into
    def handle_failed_row(row)
      row
    end

    # Override this method to do some work will all of the rows that failed to import.
    #
    # @abstract
    #
    # @note If you override this method and {#handle_failed_row}, be sure to call +super+.
    def handle_failed_rows(rows)
      rows.each { |row| handle_failed_row(row) }
    end

    # Override this method to specify how to translate values from the CSV
    #   into ruby objects.
    #
    #   You can provide an object that implements +convert+, a proc or lambda, or the
    #   the name of a method as a Symbol
    #
    # @abstract
    #
    # @example
    #   def value_converters
    #     {
    #       name: -> (value) { value.titleize }
    #       price: :convert_price,
    #       expires_at: CustomDateConverter
    #     }
    #   end
    #
    #   def convert_price(value)
    #     value || 0
    #   end
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

    # Implement this method if you'd like to rollback the transaction
    #   after it otherwise has completed.
    #
    # @abstract
    #
    # @note Only works if the `wrap_in_transaction` option is `true`
    #   (which is the default)
    #
    # @return [Boolean]
    def rollback_transaction?
      false
    end

    private

    # @private
    attr_reader :row_number

    # @api private
    # @private
    attr_reader :skipped_rows

    # @api private
    # @private
    def increment_row_number
      @row_number = row_number.to_i + 1
    end

    def add_skipped_row(row)
      @skipped_rows ||= []
      skipped_rows << row
    end

    # @api private
    # @private
    def column_mapping_options
      case column_mapping
      when Hash
        { key_mapping: column_mapping, remove_unmapped_keys: true }
      when Array
        { user_provided_headers: column_mapping }
      else
        raise InvalidColumnMapping, "#column_mapping must be a Hash or an Array: got `#{column_mapping}`"
      end
    end

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
    def transaction_if_needed
      if merged_options[:wrap_in_transaction]
        import_into.transaction do
          yield
          raise ActiveRecord::Rollback if rollback_transaction?
        end
      else
        yield
      end
    end

    # @api private
    # @private
    def process_import_results(import_results)
      import_results.each_with_object(
        invalid_records: [],
        total_inserted: 0,
        inserted_ids: [],
        skipped_rows: skipped_rows
      ) do |import_result, total_results|
        total_results[:invalid_records] += import_result.failed_instances
        total_results[:total_inserted] += import_result.num_inserts
        total_results[:inserted_ids] += import_result.ids
      end
    end
  end
end
