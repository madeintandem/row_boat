# frozen_string_literal: true

module RowBoat
  class Base
    attr_reader :csv_source

    def initialize(csv_source)
      @csv_source = csv_source
    end

    def import_into
      raise NotImplementedError, not_implemented_error_message(__method__)
    end

    def column_mapping
      raise NotImplementedError, not_implemented_error_message(__method__)
    end

    def csv_options
      {}
    end

    def import_options
      {}
    end

    private

    def not_implemented_error_message(method_name)
      "Subclasses of #{self.class.name} must implement `#{method_name}`"
    end
  end
end
