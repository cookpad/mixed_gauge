require 'spec_helper'

RSpec.describe MixedGauge::Routing do
  let(:config) { MixedGauge::ClusterConfig.new(:test) }
  before do
    config.define_slots(1..1024)
    config.register(1..512, :connection_x)
    config.register(513..1024, :connection_y)
  end
  let(:routing) { described_class.new(config) }

  it 'routes to a connection name' do
    expect(routing.route('xxx')).to eq(:connection_y)
  end
end
