require 'spec_helper'

# See spec/models.rb about model definitions
RSpec.describe MixedGauge::ReplicationMapping do
  let(:mapping) { described_class.new(slave: :UserReadonly) }

  describe '#switch' do
    let(:key) { 'xxx' }
    let(:shard_for_master) { User.shard_for(key) }
    let(:shard_for_slave) { UserReadonly.shard_for(key) }

    context 'without block' do
      it 'retuns target shard model' do
        expect(mapping.switch(shard_for_master, :slave)).to eq(shard_for_slave)
      end
    end

    context 'with block' do
      it 'yields target shard model and retuns block result' do
        result = mapping.switch(shard_for_master, :slave) do |m|
          expect(m).to eq(shard_for_slave)
          1
        end
        expect(result).to eq(1)
      end
    end
  end
end
