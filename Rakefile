require 'rubygems'
require 'bundler/setup'

require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

task :performance_test do
  ruby 'spec/performance_test.rb'
end

task :default => [:spec, :performance_test]
