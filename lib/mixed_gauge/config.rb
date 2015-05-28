module MixedGauge
  class Config
    DEFAULT_HASH_FUNCTION = -> (key) { Digest::MD5.hexdigest(key).to_i(16) }

    attr_reader :hash_proc, :cluster_configs

    def initialize
      @cluster_configs = {}
      @hash_proc = DEFAULT_HASH_FUNCTION
    end

    # Define config for specific cluster.
    # @param [Symbol] cluster_name
    # @return [nil]
    # @example
    #   config.define_cluster(:user) do |cluster|
    #     cluster.define_slots(1..1048576)
    #     cluster.register(1..524288, :production_user_001)
    #     cluster.register(524289..1048576, :production_user_002)
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

    # Register arbitrary hash function. Hash function must be a proc and
    # must return integer.
    # @example
    #   # gem install fnv
    #   require "fnv"
    #   Mixedgauge.configure do |config|
    #     config.register_hash_function do |key|
    #       FNV.new.fnv1a_64(key)
    #     end
    #   end
    def register_hash_function(&block)
      raise ArgumentError if block.arity != 1
      raise ArgumentError unless block.call('test value').is_a? Integer
      @hash_proc = block
    end
  end
end
