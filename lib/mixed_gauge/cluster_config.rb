module MixedGauge
  # Mapping of slot -> connection_name.
  class ClusterConfig
    attr_reader :name

    # @param [Symbol] name
    def initialize(name)
      @name = name
      @connection_registry = {}
    end

    # @param [Integer] size The slot size of this cluster.
    def define_slot_size(n)
      @slots = 0..(n - 1)
    end

    # @param [Range] assigned_slots The assigned range of slots of given
    #   connection (shard).
    # @param [Symbol] connection connection name
    def register(assigned_slots, connection)
      @connection_registry[assigned_slots] = connection
    end

    def validate_config!
      # TODO
      # validate non Fixnum slots.
    end

    # @return [Integer]
    def slot_size
      @slots.size
    end

    # @param [Integer] slot
    # @return [Symbol] registered connection name
    def fetch(slot)
      @connection_registry.find {|slot_range, name| slot_range.cover?(slot) }[1]
    end

    # @return [Array<Symbol>] An array of connection name
    def connections
      @connection_registry.values
    end
  end
end
