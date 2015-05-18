require 'active_support/concern'

module MixedGauge
  # @example
  #   class User < ActiveRecord::Base
  #     include MixedGauge::Model
  #     use_cluster :user
  #   end
  #
  #   alice = User.get('alice@example.com')
  #   alice.age = 1
  #   alice.save!
  module Model
    extend ActiveSupport::Concern

    included do
      self.abstruct_class = true
      class_attribute :cluster_routing, instance_writer: false
      class_attribute :sub_model_repository, instance_writer: false
    end

    module ClassMethods
      def use_cluster(name)
        config = MixedGauge.config.fetch_cluster_config(name)
        self.cluster_routing = MixedGauge::Routing.new(config)
        self.sub_model_repository = MixedGauge::SubModelRepository.new(config)
      end

      # @param [String] hash_key
      # @return [ActiveRecord::Base] A auto-generated sub model of included model
      def get(hash_key)
        sub_model_repository.fetch(get_connection(hash_key))
      end

      # XXX: for temporary testing
      def get_connection(hash_key)
        cluster_routing.route(hash_key)
      end
    end
  end
end
