require 'spec_helper'

RSpec.describe MixedGauge::Config do
  let(:config) { described_class.new }

  describe 'hash function registration' do
    let(:key) { 'test value' }

    context 'when default' do
      it 'returns default hash function' do
        expect(config.hash_proc.call(key)).to be_a(Integer)
      end
    end

    context 'when given proc which does not accept any parameters' do
      it 'raises ArgumentError' do
        expect { config.register_hash_function { 1 } }.to raise_error(ArgumentError)
      end
    end

    context 'when given proc wihch returns string' do
      it 'raises ArgumentError' do
        expect { config.register_hash_function { |_key| 'x' } }.to raise_error(ArgumentError)
      end
    end

    context 'when given proper hash function proc' do
      it 'sets given proc' do
        config.register_hash_function { |_key| 1 }
        expect(config.hash_proc.call(key)).to eq(1)
      end
    end
  end
end
