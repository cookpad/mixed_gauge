require 'active_support/concern'

module MixedGauge
  # @example
  #   class User < ActiveRecord::Base
  #     include MixedGauge::Model
  #     use_cluster :user
  #     def_distkey :email
  #   end
  #
  #   User.put!(email: 'alice@example.com', name: 'alice')
  #
  #   alice = User.get('alice@example.com')
  #   alice.age = 1
  #   alice.save!
  #
  #   User.all_shards.flat_map {|m| m.where(name: 'alice') }.compact
  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :cluster_routing, instance_writer: false
      class_attribute :sub_model_repository, instance_writer: false
      class_attribute :distkey, instance_writer: false
    end

    module ClassMethods
      # The cluster config must be defined before `use_cluster`.
      # @param [Symbol] A cluster name which is set by MixedGauge.configure
      def use_cluster(name)
        config = MixedGauge.config.fetch_cluster_config(name)
        self.cluster_routing = MixedGauge::Routing.new(config)
        self.sub_model_repository = MixedGauge::SubModelRepository.new(config, self)
        self.abstract_class = true
      end

      # Distkey is a column. mixed_gauge hashes that value and determine which
      # shard to store.
      # @param [Symbol] column
      def def_distkey(column)
        self.distkey = column.to_sym
      end

      # Create new record with given attributes in proper shard for given key.
      # When distkey value is empty, raises MixedGauge::MissingDistkeyAttribute
      # error.
      # @param [Hash] attributes
      # @return [ActiveRecord::Base] A sub class instance of included model
      # @raise [MixedGauge::MissingDistkeyAttribute]
      def put!(attributes)
        raise '`distkey` is not defined. Use `def_distkey`.' unless distkey
        @before_put_callback.call(attributes) if @before_put_callback

        if key = attributes[distkey] || attributes[distkey.to_s]
          shard_for(key).create!(attributes)
        else
          raise MixedGauge::MissingDistkeyAttribute
        end
      end

      # Returns nil when not found. Except that, is same as `.get!`.
      # @param [String] key
      # @return [ActiveRecord::Base, nil] A sub model instance of included model
      def get(key)
        raise 'key must be a String' unless key.is_a?(String)
        shard_for(key.to_s).find_by(distkey => key)
      end

      # `.get!` raises MixedGauge::RecordNotFound which is child class of
      # `ActiveRecord::RecordNotFound` so you can rescue that exception as same
      # as AR's RecordNotFound.
      # @param [String] key
      # @return [ActiveRecord::Base] A sub model instance of included model
      # @raise [MixedGauge::RecordNotFound]
      def get!(key)
        get(key) or raise MixedGauge::RecordNotFound
      end

      # Register hook to assign auto-generated distkey or something.
      # Sometimes you want to generates distkey value before validation. Since
      # mixed_gauge generates sub class of your models, AR's callback is not
      # usesless for this usecase, so mixed_gauge offers its own callback method.
      # @example
      #   class User
      #     include MixedGauge::Model
      #     use_cluster :user
      #     def_distkey :name
      #     before_put do |attributes|
      #       attributes[:name] = generate_name unless attributes[:name]
      #     end
      #   end
      def before_put(&block)
        @before_put_callback = block
      end

      # Returns a generated sub class of this model which is connected proper
      # shard for given key.
      # @param [String] key A value of distkey
      # @return [Class] A sub model for this distkey value
      def shard_for(key)
        connection_name = cluster_routing.route(key.to_s)
        sub_model_repository.fetch(connection_name)
      end

      # Returns all generated sub class of this model. Useful to query to
      # all shards.
      # @return [Array<Class>] An array of sub models
      # @example
      #   User.all_shards.flat_map {|m| m.find_by(name: 'alice') }.compact
      def all_shards
        sub_model_repository.all
      end

      # Define utility methods which uses all shards or specific shard.
      # These methods can be called from included model class.
      # @example
      #   class User
      #     include MixedGauge::Model
      #     use_cluster :user
      #     def_distkey :name
      #     parent_methods do
      #       def all_count
      #         all_shards.map {|m| m.count }.reduce(&:+)
      #       end
      #
      #       def find_from_all_by(condition)
      #         all_shards.flat_map {|m m.find_by(condition) }.compact.first
      #       end
      #     end
      #   end
      #
      #   User.put!(email: 'a@m.com', name: 'a')
      #   User.put!(email: 'b@m.com', name: 'b')
      #   User.all_count #=> 2
      #   User.find_from_all_by(name: 'b') #=> User b
      def parent_methods(&block)
        instance_eval(&block)
      end
    end
  end
end
