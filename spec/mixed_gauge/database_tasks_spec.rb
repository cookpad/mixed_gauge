require 'spec_helper'

RSpec.describe MixedGauge::DatabaseTasks do
  describe '#to_rake_task' do
    it 'retuns a Rake::Task' do
      stub_const('Rake::Task', 'test' => 1)
      expect(described_class.to_rake_task('test')).to eq(1)
    end
  end

  describe '#cluster_names' do
    it 'retuns an Array of cluster name' do
      expect(described_class.cluster_names).to eq(%i[user user_readonly])
    end
  end

  describe '#clusters' do
    it 'retuns an Array of cluster config' do
      result = described_class.clusters
      expect(result.size).to eq(2)
      expect(result).to all(a_kind_of(MixedGauge::ClusterConfig))
    end
  end

  describe '#fetch_cluster_config' do
    it 'retuns defined cluster config' do
      result = described_class.fetch_cluster_config(:user)
      expect(result).to be_a(MixedGauge::ClusterConfig)
    end

    it 'raises KeyError when cluster config is not found' do
      expect do
        described_class.fetch_cluster_config(:not_found)
      end.to raise_error(KeyError)
    end
  end

  describe '#exit_with_error' do
    it 'exits 1' do
      expect { described_class.exit_with_error }.to raise_error(SystemExit)
    end
  end

  describe '#info' do
    let(:cluster) { double(name: 'test', connections: ['db_test_001']) }
    before { allow(described_class).to receive(:clusters).and_return([cluster]) }

    it 'outputs infomation of defined clusters' do
      expect { described_class.info }.to output(/test/).to_stdout
      expect { described_class.info }.to output(/db_test_001/).to_stdout
    end
  end

  describe 'TasksForMultipleClusters' do
    describe '#invoke_task_for_all_clusters' do
      it 'calls #invoke_task' do
        allow(described_class).to receive(:cluster_names)
          .and_return(['test_cluster'])
        expect(described_class).to receive(:invoke_task)
          .with('test', 'test_cluster')

        described_class.invoke_task_for_all_clusters('test')
      end
    end

    describe '#invoke_task' do
      let(:task_name) { 'test' }
      let(:cluster_name) { 'test_cluster' }
      let(:rake_task) { double(invoke: nil, reenable: nil) }

      it 'invoke given task name with prefix then reenable the task' do
        expect(described_class).to receive(:to_rake_task)
          .at_least(:once)
          .with("mixed_gauge:#{task_name}")
          .and_return(rake_task)
        expect(rake_task).to receive(:invoke).once.with(cluster_name)
        expect(rake_task).to receive(:reenable).once
        described_class.invoke_task(task_name, cluster_name)
      end
    end
  end

  describe 'TaskOrganizerForSingleClusterTask' do
    let(:args) { { cluster_name: 'test_cluster' } }
    let(:cluster_config) { double(connections: [:test_connection]) }

    before do
      allow(described_class).to receive(:fetch_cluster_config)
        .with(:test_cluster)
        .and_return(cluster_config)
    end

    describe '#create_all_databases' do
      it 'calls TasksForSingleConnection#create' do
        expect(described_class).to receive(:create)
        described_class.create_all_databases(args)
      end
    end

    describe '#drop_all_databases' do
      it 'calls TasksForSingleConnection#drop' do
        expect(described_class).to receive(:drop)
        described_class.drop_all_databases(args)
      end
    end

    describe '#load_schema_all_databases' do
      it 'calls TasksForSingleConnection#load_schema' do
        expect(described_class).to receive(:load_schema)
        described_class.load_schema_all_databases(args)
      end
    end

    context 'when not given cluster_name' do
      before { args.delete(:cluster_name) }

      it 'exits with error' do
        expect(described_class).not_to receive(:create)
        expect do
          described_class.create_all_databases(args)
        end.to output(/Missing cluster_name/).to_stderr.and raise_error(SystemExit)
      end
    end

    context 'when given invalid cluster_name' do
      it 'exits with error' do
        allow(described_class).to receive(:fetch_cluster_config)
          .with(:test_cluster)
          .and_raise(KeyError)

        expect(described_class).not_to receive(:create)
        expect do
          described_class.create_all_databases(args)
        end.to output(/not found/).to_stderr.and raise_error(SystemExit)
      end
    end
  end

  describe 'TasksForSingleConnection' do
    describe 'version branching' do
      def stub_ar_version(x, y, z)
        stub_const('ActiveRecord::VERSION::MAJOR', x)
        stub_const('ActiveRecord::VERSION::MINOR', y)
        stub_const('ActiveRecord::VERSION::TINY', z)
      end

      let(:run) { described_class.load_schema('test') }
      before { allow(ActiveRecord::Base).to receive(:configurations).and_return({}) }

      context 'when AR 5.0.0' do
        before { stub_ar_version(5, 0, 0) }

        it 'calls AR::Tasks::DatabaseTasks.load_schema with configuration' do
          expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:load_schema)
          run
        end
      end

      context 'when AR 4.2.1' do
        before { stub_ar_version(4, 2, 1) }

        it 'calls AR::Tasks::DatabaseTasks.load_schema_for with configuration' do
          expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:load_schema_for)
          run
        end
      end

      context 'when AR 4.1.8' do
        before { stub_ar_version(4, 1, 8) }

        it 'calls AR::Tasks::DatabaseTasks.load_schema_for with configuration' do
          expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:load_schema_for)
          run
        end
      end

      context 'when AR 4.1.7' do
        before { stub_ar_version(4, 1, 7) }

        it 'calls establish_connection then calls AR::Tasks::DatabaseTasks.load_schema without configuration' do
          expect(ActiveRecord::Base).to receive(:establish_connection)
          expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:load_schema)
          run
        end
      end

      context 'when AR 4.0.9' do
        before { stub_ar_version(4, 0, 9) }

        it 'raises error and show not supported' do
          expect { run }.to raise_error(/not supported/)
        end
      end
    end
  end
end
