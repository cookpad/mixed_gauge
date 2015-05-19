module MixedGauge
  class SubModelRepository
    attr_reader :base_class

    def initialize(cluster_config, base_class)
      @base_class = base_class

      sub_models = cluster_config.connections.map do |connection_name|
        [connection_name, generate_sub_model(connection_name)]
      end
      @sub_models = Hash[sub_models]
    end

    # @param [Symbol] connection_name
    # @return [Class] A sub model of given base class
    def fetch(connection_name)
      @sub_models.fetch(connection_name)
    end

    # @return [Array<Class>]
    def all
      @sub_models.values
    end

    private

    def generate_sub_model(connection_name)
      base_class_name = @base_class.name
      class_name = generate_class_name(connection_name)
      sub_model = Class.new(base_class) do
        self.table_name = base_class.table_name
        eval <<-METHOD
          def self.name
            "#{base_class_name}::#{class_name}"
          end
        METHOD
      end
      sub_model.class_eval { establish_connection(connection_name) }
      sub_model
    end

    def generate_class_name(name)
      "GeneratedModel#{name.to_s.gsub('-', '_').classify}"
    end
  end
end
