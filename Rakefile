require 'rubygems'
require 'bundler/setup'

require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: %i[spec rubocop]

task :performance_test do
  ruby 'spec/performance_test.rb'
end

task default: %i[spec rubocop performance_test]
