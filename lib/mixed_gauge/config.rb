module MixedGauge
  class Config
    def initialize
      @cluster_configs = {}
    end

    def define_cluster(name, &block)
      cluster_config = ClusterConfig.new(name)
      cluster_config.instance_eval(&block)
      @cluster_configs[name] = cluster_config
    end

    def fetch_cluster_config(name)
      @cluster_configs.fetch(name)
    end
  end
end
