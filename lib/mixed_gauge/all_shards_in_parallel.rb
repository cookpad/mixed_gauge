module MixedGauge
  # Support parallel execution with each shard and deal with AR connection
  # management in parallel execution.
  class AllShardsInParallel
    # @param [Array<Class>] An array of sub model class
    def initialize(shards)
      @shards = shards
    end

    # @yield [Class] A sub model class
    # @return [Array] A result
    # @example
    #   User.all_shards_in_parallel.map(&:count).reduce(&:+)
    def map(&block)
      commands = @shards.map do |m|
        Expeditor::Command.new { m.connection_pool.with_connection { yield m } }
      end
      commands.each(&:start)
      commands.map(&:get)
    end

    # @yield [Class] A sub model class
    # @return [Array] A result
    # @example
    #   User.all_shards_in_parallel.flat_map {|m| m.where(age: 1) }
    def flat_map(&block)
      map(&block).flatten
    end

    # @yield [Class] A sub model class
    # @return [MixedGauge::AllShardsInParallel]
    # @example
    #   User.all_shards_in_parallel.each {|m| puts m.count }
    def each(&block)
      map(&block) if block_given?
      self
    end
  end
end
