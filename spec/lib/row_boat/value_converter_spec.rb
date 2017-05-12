# frozen_string_literal: true

require "spec_helper"

RSpec.describe RowBoat::ValueConverter do
  describe "#initialize" do
    let(:block) { proc { "I'm a block" } }
    subject { described_class.new(&block) }

    it "hangs on to its block as converter" do
      expect(subject.converter).to eq(block)
    end
  end

  describe "#convert" do
    let(:value) { "I'm a value with " }
    let(:block) { proc { |given_value| value + given_value } }
    subject { described_class.new(&block) }

    it "invokes the converter and returns that value" do
      expect(subject.convert("foo")).to eq("I'm a value with foo")
    end
  end
end
