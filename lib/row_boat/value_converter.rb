# frozen_string_literal: true

module RowBoat
  # @api private
  class ValueConverter
    attr_reader :converter

    def initialize(&block)
      @converter = block
    end

    def convert(value)
      converter.call(value)
    end
  end
end
