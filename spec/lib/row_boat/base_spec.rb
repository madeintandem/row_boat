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

    it "includes the `wrap_in_transaction` key as true" do
      expect(subject.options[:wrap_in_transaction]).to eq(true)
    end

    it "includes the key `chunk_size`" do
      expect(subject.options[:chunk_size]).to eq(500)
    end

    it "includes the `validate` key as true" do
      expect(subject.options[:validate]).to eq(true)
    end
  end

  describe "#import" do
    let(:import_class) { build_subclass }
    let(:csv_options) { RowBoat::Helpers.extract_csv_options(subject.options) }

    subject { import_class.new(product_csv_path) }

    def build_subclass_with_options(added_options)
      build_subclass do
        define_method :options do
          super().merge(added_options)
        end
      end
    end

    it "imports the csv into the database" do
      expect { subject.import }.to change(Product, :count).from(0).to(3)
    end

    it "passes the csv options to the csv parser" do
      expect(SmarterCSV).to receive(:process).with(product_csv_path, csv_options).and_call_original
      subject.import
    end

    it "imports the rows" do
      expect(subject).to receive(:import_rows) do |rows|
        expect(rows).to be_present
        double(failed_instances: [])
      end
      subject.import
    end

    context "wrapping in a transaction" do
      let(:import_class) do
        build_subclass_with_options(wrap_in_transaction: true, chunk_size: 1)
      end

      subject { import_class.new(product_csv_path) }

      before do
        Product.create!(name: "foo", rank: 3)
      end

      it "wraps the imports in a transaction and rolls it back when there's an error" do
        expect(Product.count).to eq(1)
        expect { subject.import }.to raise_error(ActiveRecord::RecordNotUnique)
        expect(Product.count).to eq(1)
      end
    end

    context "not wrapping in a transaction" do
      let(:import_class) do
        build_subclass_with_options(wrap_in_transaction: false, chunk_size: 1)
      end

      subject { import_class.new(product_csv_path) }

      before do
        Product.create!(name: "foo", rank: 3)
      end

      it "does not wrap the import in a transaction" do
        expect(Product.count).to eq(1)
        expect { subject.import }.to raise_error(ActiveRecord::RecordNotUnique)
        expect(Product.count).to eq(3)
      end
    end

    context "with validation" do
      let(:import_class) { build_subclass_with_options(validate: true, chunk_size: 3) }

      subject { import_class.new(invalid_product_csv_path) }

      it "ignores invalid rows" do
        expect { subject.import }.to change(Product, :count).from(0).to(2)
      end

      it "returns invalid rows" do
        result = subject.import
        expect(result[:invalid_records]).to be_present
        expect(result[:invalid_records].size).to eq(5)
        expect(result[:invalid_records]).to all(be_a(Product))
        expect(result[:invalid_records].map(&:description)).to all(eq("invalid"))
      end
    end

    context "without validation" do
      let(:import_class) { build_subclass_with_options(validate: false) }

      subject { import_class.new(invalid_product_csv_path) }

      it "does not raise an error when given an invalid row" do
        expect { subject.import }.to_not raise_error
      end

      it "returns an empty array for invalid records" do
        expect(subject.import[:invalid_records]).to eq([])
      end
    end
  end

  describe "#preprocess_row" do
    let(:row) { { column: :value } }

    it "is the given row" do
      expect(subject.preprocess_row(row)).to equal(row)
    end
  end

  describe "#import_rows" do
    let(:row) { { name: "foo", rank: 1 } }
    let(:rows) { [row] }
    let(:import_class) do
      build_subclass do
        define_method :preprocess_row do |row|
          row.merge(name: "preprocessed")
        end
      end
    end
    subject { import_class.new(product_csv_path) }
    let(:import_options) { RowBoat::Helpers.extract_import_options(subject.options) }

    it "imports the given rows" do
      expect { subject.import_rows(rows) }.to change(Product, :count).from(0).to(1)
    end

    it "passes the import options to the active record class' import method" do
      expect(subject.import_into).to receive(:import) do |rows, given_import_options|
        expect(rows).to be_present
        expect(given_import_options).to eq(import_options)
        double(failed_instances: [])
      end
      subject.import_rows(rows)
    end

    it "preprocesses the rows before importing them" do
      subject.import_rows(rows)
      expect(Product.first.name).to eq("preprocessed")
    end
  end
end
