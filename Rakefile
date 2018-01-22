require 'rubygems'
require 'bundler/setup'

require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: %i[spec rubocop]

task :performance_test do
  ruby 'spec/performance_test.rb'
end

task :default => [:spec, :rubocop, :performance_test]
