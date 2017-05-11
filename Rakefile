# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "standalone_migrations"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new
StandaloneMigrations::Tasks.load_tasks

task default: %i[rubocop spec]
