# frozen_string_literal: true

require "spec_helper"

RSpec.describe RowBoat::Helpers do
  describe ".extract_csv_options" do
    let(:csv_options) do
      subject::CSV_OPTION_KEYS.each_with_object({}) do |key, options|
        options[key] = true
      end
    end
    let(:too_many_options) { csv_options.merge(foo: false) }

    it "is only options for csv parsing" do
      expect(csv_options).to be_present
      expect(subject.extract_csv_options(too_many_options)).to eq(csv_options)
    end
  end

  describe ".extract_import_options" do
    let(:import_options) do
      subject::IMPORT_OPTION_KEYS.each_with_object({}) do |key, options|
        options[key] = true
      end
    end
    let(:too_many_options) { import_options.merge(foo: false) }

    it "is only options for importing data" do
      expect(import_options).to be_present
      expect(subject.extract_import_options(too_many_options)).to eq(import_options)
    end
  end
end
