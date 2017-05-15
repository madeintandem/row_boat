# frozen_string_literal: true

# @api private
module RowBoat
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
