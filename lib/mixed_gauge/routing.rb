require 'digest/md5'

module MixedGauge
  class Routing
    def initialize(cluster_config)
      @cluster_config = cluster_config
    end

    # @param [String] hash_key
    # @return [String] connection name
    def route(hash_key)
      slot = hash_f(hash_key) % @cluster_config.slot_count
      @cluster_config.fetch(slot)
    end

    # @param [String] hash_key
    # @return [Integer]
    def hash_f(hash_key)
      Digest::MD5.hexdigest(hash_key).to_i(16)
    end
  end
end
