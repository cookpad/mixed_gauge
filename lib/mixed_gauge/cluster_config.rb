module MixedGauge
  class ClusterConfig
    attr_reader :name

    # @param [Symbol] name
    def initialize(name)
      @name = name
      @nodes = {}
    end

    # @param [Range] slots
    def define_slots(slots)
      @slots = slots
    end

    # @param [Range] slots
    # @param [Symbol] node
    def add_node(slots, node)
      @nodes[slots] = node
    end

    def validate_config!
      # TODO
    end
  end
end
