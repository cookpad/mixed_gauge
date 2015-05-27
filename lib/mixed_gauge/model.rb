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
      # @param [Symbol] A cluster name which is set by MixedGauge.configure
      def use_cluster(name)
        config = MixedGauge.config.fetch_cluster_config(name)
        self.cluster_routing = MixedGauge::Routing.new(config)
        self.sub_model_repository = MixedGauge::SubModelRepository.new(config, self)
        self.abstract_class = true
      end

      # @param [Symbol] column
      def def_distkey(column)
        self.distkey = column.to_sym
      end

      # @param [Object] key 
      # @return [ActiveRecord::Base] A auto-generated sub model of included model
      def get(key)
        shard_for(key.to_s).find_by(distkey => key)
      end

      # @param [Hash] attributes
      # @return [ActiveRecord::Base] A sub class instance of included model
      def put!(attributes)
        @before_put_callback.call(attributes) if @before_put_callback

        if key = attributes[distkey] || attributes[distkey.to_s]
          shard_for(key).create!(attributes)
        else
          raise MixedGauge::MissingDistkeyAttribute
        end
      end

      # Register hook to assign auto-generated distkey.
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

      # @param [Object] key A value of distkey
      # @return [Class] A sub model for this distkey value
      def shard_for(key)
        connection_name = cluster_routing.route(key.to_s)
        sub_model_repository.fetch(connection_name)
      end

      # @return [Array<Class>] An array of sub models
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
