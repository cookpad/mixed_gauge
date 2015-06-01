require 'simplecov'
require 'coveralls'
Coveralls.wear!
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter '/spec'
end

require 'pry'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'mixed_gauge'

base = { 'adapter' => 'sqlite3' }
ActiveRecord::Base.configurations = {
  'test_user_001' => base.merge('database' => 'user_001.sqlite3'),
  'test_user_002' => base.merge('database' => 'user_002.sqlite3'),
  'test_user_003' => base.merge('database' => 'user_003.sqlite3'),
  'test_user_004' => base.merge('database' => 'user_004.sqlite3'),
  'test' => base.merge('database' => 'default.sqlite3')
}
ActiveRecord::Base.establish_connection(:test)

MixedGauge.configure do |config|
  config.define_cluster(:user) do |cluster|
    cluster.define_slots(1..1048576)
    cluster.register(1..262144, :test_user_001)
    cluster.register(262145..524288, :test_user_002)
    cluster.register(524289..786432, :test_user_003)
    cluster.register(786433..1048576, :test_user_004)
  end
end

class User < ActiveRecord::Base
  include MixedGauge::Model
  use_cluster(:user)
end

RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Tasks::DatabaseTasks.db_dir = File.expand_path('..', __FILE__)
    ActiveRecord::Tasks::DatabaseTasks.root = File.expand_path('../..', __FILE__)
    ActiveRecord::Tasks::DatabaseTasks.env = 'test'
    args = { cluster_name: 'user' }
    back, $stdout = $stdout, StringIO.new
    MixedGauge::DatabaseTasks.drop_all_databases(args)
    MixedGauge::DatabaseTasks.create_all_databases(args)
    MixedGauge::DatabaseTasks.load_schema_all_databases(args)
    $stdout = back
  end

  config.after(:suite) do
    MixedGauge::DatabaseTasks.drop_all_databases(cluster_name: 'user')
  end

  config.after(:each) do
    User.all_shards.each(&:delete_all)
  end

  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = false
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.disable_monkey_patching!

  config.warnings = true if ENV['RSPEC_WARNING'] == '1'

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.profile_examples = 10 if ENV['PROFILE_EXAMPLE'] == '1'

  config.order = :random
  Kernel.srand config.seed
end
