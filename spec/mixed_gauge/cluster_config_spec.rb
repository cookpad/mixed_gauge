require 'spec_helper'

RSpec.describe MixedGauge::ClusterConfig do
  let(:config) { MixedGauge::ClusterConfig.new(:test) }

  describe '#validate_config!' do
    it 'passes with valid configuration' do
      config.define_slot_size(10)
      config.register(0..4, :connection_a)
      config.register(5..9, :connection_b)

      expect { config.validate_config! }.not_to raise_error
    end

    it 'checks duplication' do
      config.define_slot_size(10)
      config.register(0..4, :connection_a)
      config.register(4..9, :connection_b)

      expect { config.validate_config! }.to raise_error(/`4`/)
      expect { config.validate_config! }.to raise_error(/connection_a/)
      expect { config.validate_config! }.to raise_error(/connection_b/)
    end

    it 'checks invalid start point' do
      config.define_slot_size(10)
      config.register(1..4, :connection_a)
      config.register(5..9, :connection_b)

      expect { config.validate_config! }.to raise_error(/`1`/)
      expect { config.validate_config! }.to raise_error(/connection_a/)
    end

    it 'checks end point miss macthing' do
      config.define_slot_size(10)
      config.register(0..4, :connection_a)
      config.register(5..10, :connection_b)

      expect { config.validate_config! }.to raise_error(/`10`/)
      expect { config.validate_config! }.to raise_error(/connection_b/)
    end
  end

  describe '#slot_size' do
    before do
      config.define_slot_size(10)
      config.register(0..4, :connection_a)
      config.register(5..9, :connection_b)
    end

    subject { config.slot_size }
    it { is_expected.to eq(10) }
  end
end
