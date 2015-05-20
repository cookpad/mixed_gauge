require 'digest/md5'

module MixedGauge
  class Routing
    # @param [ClusterConfig] cluster_config
    def initialize(cluster_config)
      @cluster_config = cluster_config
    end

    # @param [String] dist_key
    # @return [String] connection name
    def route(key)
      slot = hash_f(key) % @cluster_config.slot_count
      @cluster_config.fetch(slot)
    end

    # @param [String] key
    # @return [Integer]
    def hash_f(key)
      Digest::MD5.hexdigest(key).to_i(16)
    end
  end
end
