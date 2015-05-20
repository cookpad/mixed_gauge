require 'active_record'

require 'mixed_gauge/version'
require 'mixed_gauge/cluster_config'
require 'mixed_gauge/config'
require 'mixed_gauge/routing'
require 'mixed_gauge/sub_model_repository'
require 'mixed_gauge/model'

module MixedGauge
  class << self
    # @return [MixedGauge::Config]
    def config
      @config ||= Config.new
    end

    def configure(&block)
      config.instance_eval(&block)
    end
  end
end
