require 'zlib'

module MixedGauge
  class Config
    DEFAULT_HASH_FUNCTION = -> (key) { Zlib.crc32(key) }

    attr_reader :hash_proc, :cluster_configs

    def initialize
      @cluster_configs = {}
      @hash_proc = DEFAULT_HASH_FUNCTION
    end

    # Define config for specific cluster.
    # See README.md for example.
    # @param [Symbol] cluster_name
    # @yield [MixedGauge::ClusterConfig]
    def define_cluster(cluster_name, &block)
      cluster_config = ClusterConfig.new(cluster_name)
      cluster_config.instance_eval(&block)
      @cluster_configs[cluster_name] = cluster_config
    end

    # @param [Symbol] cluster_name
    # @return [MixedGauge::ClusterConfig]
    def fetch_cluster_config(cluster_name)
      @cluster_configs.fetch(cluster_name)
    end

    # Register arbitrary hash function. Hash function must be a proc and
    # must return integer.
    # See README.md for example.
    def register_hash_function(&block)
      raise ArgumentError if block.arity != 1
      raise ArgumentError unless block.call('test value').is_a? Integer
      @hash_proc = block
    end
  end
end
