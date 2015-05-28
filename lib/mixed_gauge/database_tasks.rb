module MixedGauge
  module DatabaseTasks
    extend self

    # Show information of database sharding config.
    def info
      puts "All clusters registered to mixed_gauge"
      puts
      clusters.each do |cluster|
        puts "= Cluster: #{cluster.name} ="
        cluster.connections.each do |name|
          puts "- #{name}"
        end
        puts
      end
    end

    # @private
    # @param [String] task_name
    # @return [Rake::Task]
    def to_rake_task(task_name)
      Rake::Task[task_name]
    end

    # @private
    # @return [Array<Symbol>]
    def cluster_names
      MixedGauge.config.cluster_configs.keys
    end

    # @private
    # @return [Array<MixedGauge::ClusterConfig>]
    def clusters
      MixedGauge.config.cluster_configs.values
    end

    # @private
    # @return [MixedGauge::ClusterConfig]
    # @raise [KeyError]
    def fetch_cluster_config(cluster_name)
      MixedGauge.config.fetch_cluster_config(cluster_name)
    end

    # For mock-ablity
    # @private
    def exit_with_error
      exit 1
    end

    module TasksForMultipleClusters
      # @param [String] task_name
      def invoke_task_for_all_clusters(task_name)
        cluster_names.each do |cluster_name|
          invoke_task(task_name, cluster_name)
        end
      end

      # @private
      # @param [String] name
      # @param [Symbol] cluster_name
      def invoke_task(name, cluster_name)
        task_name = "mixed_gauge:#{name}"
        to_rake_task(task_name).invoke(cluster_name.to_s)
        to_rake_task(task_name).reenable
      end
    end
    extend TasksForMultipleClusters

    # Organize cluster config and handle error for invalid args, call single
    # cluster task with each single connection config.
    module TaskOrganizerForSingleClusterTask
      # @param [Hash{Symbol => String}] args
      def create_all_databases(args)
        exec_task_for_all_databases('create', args)
      end

      # @param [Hash{Symbol => String}] args
      def drop_all_databases(args)
        exec_task_for_all_databases('drop', args)
      end

      # @param [Hash{Symbol => String}] args
      def load_schema_all_databases(args)
        exec_task_for_all_databases('load_schema', args)
      end

      private

      # @param [String] task_name
      # @param [Hash{Symbol => String}] args
      def exec_task_for_all_databases(task_name, args)
        cluster_name = cluster_name_or_error(task_name, args)
        cluster = cluster_or_error(cluster_name)
        cluster.connections.each do |connection_name|
          __send__(task_name, connection_name.to_s)
        end
      end

      # @param [String] name A task name
      # @param [Hash{Symbol => String}] args
      # @return [String]
      def cluster_name_or_error(name, args)
        unless cluster_name = args[:cluster_name]
          $stderr.puts <<-MSG
Missing cluster_name. Find cluster_name via `rake mixed_gauge:info` then call `rake "mixed_gauge:#{name}[$cluster_name]"`.
          MSG
          exit_with_error
        end
        cluster_name
      end

      # @param [String] cluster_name
      # @return [MixedGauge::ClusterConfig]
      def cluster_or_error(cluster_name)
        fetch_cluster_config(cluster_name.to_sym)
      rescue KeyError
        $stderr.puts %!cluster name "#{cluster_name}" not found.!
        exit_with_error
      end
    end
    extend TaskOrganizerForSingleClusterTask

    # Create, drop, load_schema for single connection config.
    module TasksForSingleConnection
      # @param [String] connection_name
      def create(connection_name)
        configuration = ActiveRecord::Base.configurations[connection_name]
        ActiveRecord::Tasks::DatabaseTasks.create(configuration)
        # Re-configure using configuration with database
        ActiveRecord::Base.establish_connection(configuration)
      end

      # @param [String] connection_name
      def drop(connection_name)
        configuration = ActiveRecord::Base.configurations[connection_name]
        ActiveRecord::Tasks::DatabaseTasks.drop(configuration)
      end

      # @param [String] connection_name
      def load_schema(connection_name)
        configuration = ActiveRecord::Base.configurations[connection_name]
        #ActiveRecord::Base.establish_connection(configuration)
        # Use `.load_schema` for Rails > 4.2.
        # Use `.load_schema_for` for Rails <= 4.2.
        ActiveRecord::Tasks::DatabaseTasks.load_schema_for(configuration, :ruby)
      end
    end
    extend TasksForSingleConnection
  end
end
