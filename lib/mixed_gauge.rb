require 'active_record'
require 'expeditor'

require 'mixed_gauge/version'
require 'mixed_gauge/errors'
require 'mixed_gauge/cluster_config'
require 'mixed_gauge/config'
require 'mixed_gauge/routing'
require 'mixed_gauge/sub_model_repository'
require 'mixed_gauge/all_shards_in_parallel'
require 'mixed_gauge/model'

module MixedGauge
  class << self
    # @return [MixedGauge::Config]
    def config
      @config ||= Config.new
    end

    # @yield [MixedGauge::Config]
    def configure(&block)
      config.instance_eval(&block)
    end
  end
end

require 'mixed_gauge/database_tasks'
require 'mixed_gauge/railtie' if defined? Rails
