require 'spec_helper'

RSpec.describe MixedGauge::Routing do
  let(:config) { MixedGauge::ClusterConfig.new(:test) }
  before do
    config.define_slot_size(1024)
    config.register(0..511, :connection_x)
    config.register(512..1023, :connection_y)
  end
  let(:routing) { described_class.new(config) }

  it 'routes to a connection name' do
    expect(routing.route('xxx')).to eq(:connection_y)
  end
end
