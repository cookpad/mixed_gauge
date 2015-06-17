module MixedGauge
  class ShardRepository
    attr_reader :base_class

    # @param [ClusterConfig] cluster_config
    # @param [Class] base_class A AR Model
    def initialize(cluster_config, base_class)
      @base_class = base_class

      shards = cluster_config.connections.map do |connection_name|
        [connection_name, generate_model_for_shard(connection_name)]
      end
      @shards = Hash[shards]
    end

    # @param [Symbol] connection_name
    # @return [Class] A model class for this shard
    def fetch(connection_name)
      @shards.fetch(connection_name)
    end

    # @return [Array<Class>]
    def all
      @shards.values
    end

    private

    # @param [Symbol] connection_name
    # @return [Class] A sub class of given AR model.
    #   A sub class has connection setting for specific shard.
    def generate_model_for_shard(connection_name)
      base_class_name = @base_class.name
      class_name = generate_class_name(connection_name)

      model = Class.new(base_class) do
        self.table_name = base_class.table_name
        module_eval <<-RUBY, __FILE__, __LINE__ + 1
          def self.name
            "#{base_class_name}::#{class_name}"
          end
        RUBY
      end
      model.class_eval { establish_connection(connection_name) }
      model
    end

    # @param [Symbol] connection_name
    # @return [String]
    def generate_class_name(connection_name)
      "ShardFor#{connection_name.to_s.gsub('-', '_').classify}"
    end
  end
end
