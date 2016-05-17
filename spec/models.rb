base = { 'adapter' => 'sqlite3' }
ActiveRecord::Base.configurations = {
  'test_user_001' => base.merge('database' => 'user_001.sqlite3'),
  'test_user_002' => base.merge('database' => 'user_002.sqlite3'),
  'test_user_003' => base.merge('database' => 'user_003.sqlite3'),
  'test_user_004' => base.merge('database' => 'user_004.sqlite3'),
  'test_user_readonly_001' => base.merge('database' => 'user_001.sqlite3'),
  'test_user_readonly_002' => base.merge('database' => 'user_002.sqlite3'),
  'test_user_readonly_003' => base.merge('database' => 'user_003.sqlite3'),
  'test_user_readonly_004' => base.merge('database' => 'user_004.sqlite3'),
  'test' => base.merge('database' => 'default.sqlite3')
}
ActiveRecord::Base.establish_connection(:test)

MixedGauge.configure do |config|
  config.define_cluster(:user) do |cluster|
    cluster.define_slot_size(1048576)
    cluster.register(0..262143, :test_user_001)
    cluster.register(262144..524287, :test_user_002)
    cluster.register(524288..786431, :test_user_003)
    cluster.register(786432..1048575, :test_user_004)
  end

  config.define_cluster(:user_readonly) do |cluster|
    cluster.define_slot_size(1048576)
    cluster.register(0..262143, :test_user_readonly_001)
    cluster.register(262144..524287, :test_user_readonly_002)
    cluster.register(524288..786431, :test_user_readonly_003)
    cluster.register(786432..1048575, :test_user_readonly_004)
  end
end

class User < ActiveRecord::Base
  include MixedGauge::Model
  use_cluster :user
  def_distkey :email
  replicates_with slave: :UserReadonly
end

class UserReadonly < ActiveRecord::Base
  self.table_name = 'users'
  include MixedGauge::Model
  use_cluster :user_readonly
  def_distkey :email
  replicates_with master: :User
end
