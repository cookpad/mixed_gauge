module MixedGauge
  class Config
    def initialize
      @cluster_configs = {}
    end

    # @param [Symbol] cluster_name
    # @return [nil]
    # @example
    #   config.define_cluster(:user) do |c|
    #     c.define_slots(1..1024)
    #   end
    def define_cluster(cluster_name, &block)
      cluster_config = ClusterConfig.new(cluster_name)
      cluster_config.instance_eval(&block)
      @cluster_configs[cluster_name] = cluster_config
      nil
    end

    # @param [Symbol] cluster_name
    # @return [MixedGauge::ClusterConfig]
    def fetch_cluster_config(cluster_name)
      @cluster_configs.fetch(cluster_name)
    end
  end
end
