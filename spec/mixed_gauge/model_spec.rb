require 'spec_helper'

RSpec.describe MixedGauge::Model do
  let!(:model) do
    Class.new(ActiveRecord::Base) do
      def self.name
        'User'
      end

      def self.generate_name
        'xxx'
      end

      include MixedGauge::Model
      use_cluster :user
      def_distkey :email

      before_put do |attrs|
        attrs[:name] = generate_name unless attrs[:name]
      end

      parent_methods do
        def find_from_all_by_name(name)
          all_shards.map {|m| m.find_by(name: name) }.compact.first
        end
      end
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
    context 'when record exists' do
      before { model.put!(user_attributes) }
      it 'returns AR::B instance from proper node' do
        record = model.get('alice@example.com')
        expect(record).to be_a(model)
        expect(record.email).to eq('alice@example.com')
        expect(record).to be_respond_to(:save!)
      end
    end

    context 'when record not exists' do
      it 'returns nil' do
        expect(model.get('not_exist@example.com')).to be_nil
      end
    end
  end

  describe '.get!' do
    context 'when record exists' do
      before { model.put!(user_attributes) }

      it 'returns proper record' do
        record = model.get('alice@example.com')
        expect(record.email).to eq('alice@example.com')
      end
    end

    context 'when record not exists' do
      it 'raises MixedGauge::RecordNotFound' do
        expect {
          model.get!('not_exist@example.com')
        }.to raise_error(MixedGauge::RecordNotFound)
      end

      it 'raises sub class of ActiveRecord::RecordNotFound' do
        expect {
          model.get!('not_exist@example.com')
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '.before_put' do
    it 'calls registered hook before execute `put`' do
      record = model.put!(email: 'xxx@example.com')
      expect(record.name).to eq('xxx')
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

  describe '.parent_methods' do
    before do
      model.put!(user_attributes)
      model.put!(email: 'bob@example.com', name: 'bob')
    end

    it 'enables to define class methods to parent class' do
      record = model.find_from_all_by_name('bob')
      expect(record).not_to be_nil
      expect(record.name).to eq('bob')
    end
  end
end
