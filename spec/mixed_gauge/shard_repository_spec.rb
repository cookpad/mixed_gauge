require 'spec_helper'

RSpec.describe MixedGauge::SubModelRepository do
  let(:repository) { described_class.new(cluster_config, base_class) }
  let(:cluster_config) { MixedGauge.config.fetch_cluster_config(:user) }
  let(:base_class) { Class.new(ActiveRecord::Base) { def self.name; 'Test' end } }

  describe '#fetch' do
    let(:connection_name) { cluster_config.connections.first }

    it 'returns generated sub model' do
      sub_model = repository.fetch(connection_name)
      expect(sub_model).to be_respond_to(:connection)
      expect(sub_model.class).not_to eq(base_class)
    end
  end

  describe '#all' do
    it 'returns all generated sub model' do
      expect(repository.all.count).to eq(cluster_config.connections.count)
      expect(repository.all).to all(be_respond_to(:connection))
    end
  end

  describe 'class name of sub model' do
    let(:sub_model) { repository.fetch(cluster_config.connections.first) }
    subject { sub_model.name }
    it { is_expected.to match(/Test::GeneratedModel[0-9A-z]+/) }
  end
end
