# frozen_string_literal: true

module RowBoat
  module Helpers
    CSV_OPTION_KEYS = %i[
      chunk_size
      col_sep
      comment_regexp
      convert_values_to_numeric
      downcase_header
      file_encoding
      force_simple_split
      force_utf8
      headers_in_file
      invalid_byte_sequence
      keep_original_headers
      key_mapping
      quote_char
      remove_empty_hashes
      remove_empty_values
      remove_unmapped_keys
      remove_values_matching
      remove_zero_values
      row_sep
      skip_lines
      strings_as_keys
      strip_chars_from_headers
      strip_whitespace
      user_provided_headers
      value_converters
      verbose
    ].freeze

    IMPORT_OPTION_KEYS = %i[
      batch_size
      ignore
      on_duplicate_key_ignore
      recursive
      synchronize
      timestamps
      validate
    ].freeze

    class << self
      def extract_csv_options(options)
        options.slice(*CSV_OPTION_KEYS)
      end

      def extract_import_options(options)
        options.slice(*IMPORT_OPTION_KEYS)
      end
    end
  end
end
