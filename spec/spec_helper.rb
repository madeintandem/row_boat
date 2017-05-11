# frozen_string_literal: true

require "bundler/setup"
require "row_boat"
require "active_record"
require "database_cleaner"
require "yaml"

require_relative "./support/product"
require_relative "./support/product_csvs"

RSpec.configure do |config|
  config.include ProductCSVs

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.default_formatter = "doc" if config.files_to_run.one?
  config.profile_examples = 0
  config.order = :random
  Kernel.srand config.seed

  config.before :suite do
    dbconfig = YAML.load(File.open("db/config.yml"))
    ActiveRecord::Base.establish_connection(dbconfig["test"])
  end

  config.before :each do
    DatabaseCleaner.clean_with(:truncation)
  end
end
