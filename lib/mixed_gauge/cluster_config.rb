module MixedGauge
  # Mapping of slot -> connection_name.
  class ClusterConfig
    attr_reader :name

    # @param [Symbol] name
    def initialize(name)
      @name = name
      @connections = {}
    end

    # @param [Range] slots
    def define_slots(slots)
      @slots = slots
    end

    # @param [Range] slots
    # @param [Symbol] connection connection name
    def register(slots, connection)
      @connections[slots] = connection
    end

    def validate_config!
      # TODO
    end

    def slot_count
      @slots.count
    end

    # @param [Integer] slot
    # @return [Symbol] registered connection name
    def fetch(slot)
      @connections.find {|slot_range, name| slot_range.cover?(slot) }[1]
    end
  end
end
