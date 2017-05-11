# frozen_string_literal: true

require "spec_helper"

RSpec.describe RowBoat::Base do
  let(:csv_source) { "a file path" }
  subject { described_class.new(csv_source) }

  def build_subclass(&block)
    Class.new(described_class) do
      def import_into
        Product
      end

      def column_mapping
        { namey: :name, ranky: :rank, description: :description }
      end

      instance_eval(&block) if block
    end
  end

  describe ".import" do
    subject { build_subclass }

    it "imports the data in the given csv source" do
      expect { subject.import(product_csv_path) }.to change(Product, :count).from(0).to(3)
    end

    context "when initialize is overridden" do
      subject do
        build_subclass do
          define_method :initialize do |path, x, y, z, &block|
            super(path)
          end
        end
      end

      let(:block) { proc { "I'm a proc" } }
      let(:dummy) { double(import: true) }

      it "passes its arguments through to new" do
        expect(dummy).to receive(:import)

        expect(subject).to receive(:new) do |path, x, y, z, &given_block|
          expect(path).to eq(product_csv_path)
          expect(x).to eq(1)
          expect(y).to eq(2)
          expect(z).to eq(3)
          expect(given_block).to eq(block)
          dummy
        end

        subject.import(product_csv_path, 1, 2, 3, &block)
      end
    end
  end

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

  describe "#import" do
    let(:import_class) { build_subclass }
    let(:csv_options) { RowBoat::Helpers.extract_csv_options(subject.options) }

    subject { import_class.new(product_csv_path) }

    it "imports the csv into the database" do
      expect(SmarterCSV).to receive(:process).with(product_csv_path, csv_options).and_call_original
      expect { subject.import }.to change(Product, :count).from(0).to(3)
    end
  end
end
