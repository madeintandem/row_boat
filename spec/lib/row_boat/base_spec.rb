# frozen_string_literal: true

require "spec_helper"

RSpec.describe RowBoat::Base do
  let(:csv_source) { "a file path" }
  subject { described_class.new(csv_source) }

  describe "#initialize" do
    let(:csv_source) { "a file path" }
    subject { described_class.new(csv_source) }

    it "saves its csv source" do
      expect(subject.csv_source).to eq(csv_source)
    end
  end

  describe "#import_into" do
    it "raises a not implemented error" do
      expect { subject.import_into }.to raise_error(NotImplementedError, "Subclasses of RowBoat::Base must implement `import_into`")
    end
  end

  describe "#column_mapping" do
    it "raises a not implemented error" do
      expect { subject.column_mapping }.to raise_error(NotImplementedError, "Subclasses of RowBoat::Base must implement `column_mapping`")
    end
  end

  describe "#options" do
    let(:column_mapping) { { column: :map } }
    before do
      expect(subject).to receive(:column_mapping).and_return(column_mapping)
    end

    it "is a hash" do
      expect(subject.options).to be_a(Hash)
    end

    it "includes the column_mapping as `key_mapping`" do
      expect(subject.options[:key_mapping]).to eq(column_mapping)
    end

    it "includes the `remove_unmapped_keys` as true" do
      expect(subject.options[:remove_unmapped_keys]).to eq(true)
    end
  end
end
