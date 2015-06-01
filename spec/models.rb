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
  use_cluster :user
  def_distkey :email
end
