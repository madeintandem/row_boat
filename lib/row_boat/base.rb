# frozen_string_literal: true

require "active_record"
require "activerecord-import"
require "smarter_csv"

module RowBoat
  class Base
    attr_reader :csv_source

    def initialize(csv_source)
      @csv_source = csv_source
    end

    def import
      csv_options = ::RowBoat::Helpers.extract_csv_options(options)
      rows = ::SmarterCSV.process(csv_source, csv_options)
      import_into.import!(rows)
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
        remove_unmapped_keys: true
      }
    end

    private

    def not_implemented_error_message(method_name)
      "Subclasses of #{self.class.name} must implement `#{method_name}`"
    end
  end
end
