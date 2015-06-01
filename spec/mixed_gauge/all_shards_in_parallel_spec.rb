require 'spec_helper'

RSpec.describe MixedGauge::AllShardsInParallel do
  let(:model_class) { User }
  let(:instance) { described_class.new(model_class.all_shards) }

  describe '#map' do
    it 'maps in parallel' do
      expect(instance.map(&:count).reduce(&:+)).to eq(0)
      model_class.put!(name: 'Alice', email: 'alice@example.com')
      expect(instance.map(&:count).reduce(&:+)).to eq(1)
    end
  end

  describe '#flat_map' do
    before do
      model_class.put!(name: 'Alice', email: 'alice@example.com')
      model_class.put!(name: 'Humpty', email: 'humpty@example.com')
      model_class.put!(name: 'Alice', email: 'other@example.com')
    end

    it 'flat_maps in parallel' do
      result = instance.flat_map {|m| m.where(name: 'Alice') }
      expect(result.size).to eq(2)
    end
  end

  describe '#each' do
    it 'enables to query in parallel' do
      expect {
        instance.each {|_| print 'XXX' }
      }.to output('XXX' * 4).to_stdout
    end

    it 'returns self when block is not given' do
      expect(instance.each).to be_a(described_class)
    end
  end
end
