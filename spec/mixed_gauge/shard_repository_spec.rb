require 'spec_helper'

RSpec.describe MixedGauge::ShardRepository do
  let(:repository) { described_class.new(cluster_config, base_class) }
  let(:cluster_config) { MixedGauge.config.fetch_cluster_config(:user) }
  let(:base_class) do
    Class.new(ActiveRecord::Base) do
      def self.name
        'User'
      end
    end
  end

  describe '#fetch' do
    let(:connection_name) { cluster_config.connections.first }

    it 'returns generated model for shard' do
      shard = repository.fetch(connection_name)
      expect(shard).to be_respond_to(:connection)
      expect(shard.class).not_to eq(base_class)
    end
  end

  describe '#all' do
    it 'returns all generated model' do
      expect(repository.all.count).to eq(cluster_config.connections.count)
      expect(repository.all).to all(be_respond_to(:connection))
    end
  end

  describe 'class name of shard model' do
    let(:shard) { repository.fetch(cluster_config.connections.first) }
    subject { shard.name }
    it { is_expected.to match(/User::ShardFor[0-9A-z]+/) }
  end
end
