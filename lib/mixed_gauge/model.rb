require 'active_support/concern'

module MixedGauge
  # @example
  #   class User < ActiveRecord::Base
  #     include MixedGauge::Model
  #     use_cluster :user
  #     distkey :email
  #   end
  #
  #   User.put!(email: 'alice@example.com', name: 'alice')
  #
  #   alice = User.get('alice@example.com')
  #   alice.age = 1
  #   alice.save!
  #
  #   User.all_shards.flat_map {|m| m.where(name: 'alice') }
  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :cluster_routing, instance_writer: false
      class_attribute :sub_model_repository, instance_writer: false
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
      def distkey(column)
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
        if key = attributes[distkey] || attributes[distkey.to_s]
          shard_for(key).create!(attributes)
        else
          raise MixedGauge::MissingDistkeyAttribute
        end
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
    end
  end
end
