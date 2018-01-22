module MixedGauge
  # Manages mapping of each database connection
  class ReplicationMapping
    def initialize(mapping)
      @mapping = mapping
      @lock = Mutex.new
    end

    # @param [Class] A shard model having connection to specific shard
    # @param [Symbol] A role name of target cluster.
    # @return [Class, Object] if block given then yielded result else
    #   target shard model.
    def switch(from, role_name)
      @lock.synchronize { constantize! unless constantized? }

      model = @mapping.fetch(role_name)
      target_shard_model = model.shard_repository.fetch_by_slots(from.assigned_slots)

      if block_given?
        target_shard_model.connection_pool.with_connection { yield target_shard_model }
      else
        target_shard_model
      end
    end

    private

    def constantize!
      @mapping = Hash[@mapping.map { |k, name| [k, name.to_s.constantize] }]
    end

    def constantized?
      @mapping.values.first.is_a? Class
    end
  end
end
