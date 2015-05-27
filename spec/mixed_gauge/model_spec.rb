require 'spec_helper'

RSpec.describe MixedGauge::Model do
  let!(:model) do
    Class.new(ActiveRecord::Base) do
      def self.name
        'User'
      end

      include MixedGauge::Model
      use_cluster :user
      def_distkey :email
    end
  end

  let(:user_attributes) { { name: 'Alice', email: 'alice@example.com' } }

  describe '.put!' do
    it 'creates new record into proper node' do
      record = model.put!(user_attributes)
      expect(record).to be_a(model)
      expect(record.email).to eq('alice@example.com')
      expect(record).to be_respond_to(:save!)
    end

    context 'without distkey attributes' do
      before { user_attributes.delete(:email) }

      it 'raises MissingDistkeyAttribute error' do
        expect {
          model.put!(user_attributes)
        }.to raise_error(MixedGauge::MissingDistkeyAttribute)
      end
    end
  end

  describe '.get' do
    before { model.put!(user_attributes) }

    it 'gets AR::B instance from proper node' do
      record = model.get('alice@example.com')
      expect(record).to be_a(model)
      expect(record.email).to eq('alice@example.com')
      expect(record).to be_respond_to(:save!)
    end
  end

  describe '.shard_for' do
    before { model.put!(user_attributes) }

    it 'enables to use finder method' do
      record = model.shard_for('alice@example.com').find_by(name: 'Alice')
      expect(record).not_to be_nil
      expect(record.name).to eq('Alice')
    end
  end

  describe '.all_shards' do
    before { model.put!(user_attributes) }

    it 'returns all AR model classes and can search by finder methods' do
      records = model.all_shards.flat_map {|m| m.find_by(name: 'Alice') }.compact
      expect(records.size).to eq(1)
    end
  end
end
