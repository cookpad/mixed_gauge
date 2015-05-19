require 'pry'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'mixed_gauge'

base = { adapter: 'sqlite3' }
ActiveRecord::Base.configurations = {
  'user_001' => base.merge(database: 'user_001.sqlite3'),
  'user_002' => base.merge(database: 'user_002.sqlite3'),
  'user_003' => base.merge(database: 'user_003.sqlite3'),
  'user_004' => base.merge(database: 'user_004.sqlite3'),
  'default' => base.merge(database: 'default.sqlite3')
}
ActiveRecord::Base.establish_connection(:default)

MixedGauge.configure do |config|
  config.define_cluster(:user) do |cluster|
    cluster.define_slots(1..1024)
    cluster.register(1..256, :user_001)
    cluster.register(257..512, :user_002)
    cluster.register(513..768, :user_003)
    cluster.register(769..1024, :user_004)
  end
end

class User < ActiveRecord::Base
  include MixedGauge::Model
  use_cluster(:user)
end

RSpec.configure do |config|
  config.before(:suite) do
    User.all_shards.each do |model|
      model.connection.execute(
        <<-SQL
        CREATE TABLE users (
          email TEXT PRIMARY KEY,
          name TEXT
        )
        SQL
      )
    end
  end

  config.after(:suite) do
    ActiveRecord::Base.configurations.each_value do |c|
      FileUtils.rm_f(c[:database])
    end
  end

  config.after(:each) do
    User.all_shards.each(&:delete_all)
  end
end
