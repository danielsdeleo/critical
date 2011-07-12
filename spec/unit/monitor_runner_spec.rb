require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module TestHarness
  class MetricForMonitorRunnerSpec < Critical::MetricBase
    self.metric_name = :process_count
    monitors :processes_by_name

    collects { :collected }

    def graphite_handler
      @graphite_handler
    end
  end
end

describe MonitorRunner do
  before do
    MonitorCollection.instance.reset!
    @metric_spec = MetricSpecification.new(TestHarness::MetricForMonitorRunnerSpec, "unicorn", %w[appservers], Proc.new {})

    puts @metric_spec.fqn
    MonitorCollection.instance.push(@metric_spec)

    @ipc = ProcessManager::IPCData.new(nil, nil)
  end

  it "holds a copy of its IPC instructions" do
    runner = MonitorRunner.new(@ipc)
    runner.ipc.should equal(@ipc)
  end

  it "looks up a monitor in the collection" do
    @metric = @metric_spec.new_metric
    @metric_spec.stub!(:new_metric).and_return(@metric)
    @metric.should_receive(:collect)
    runner = MonitorRunner.new(@ipc)
    runner.run_monitor("/appservers/process_count(unicorn)")
  end

  context "when graphite trending has been disabled" do
    before do
      Critical.config.disable_graphite = true

      MonitorCollection.instance.reset!
      @metric_spec = MetricSpecification.new(TestHarness::MetricForMonitorRunnerSpec, "unicorn", %w[appservers], Proc.new {})

      MonitorCollection.instance.push(@metric_spec)

      @ipc = ProcessManager::IPCData.new(nil, nil)
    end

    it "does not provide the metric with a graphite handler" do
      dispatcher = OutputHandler::Dispatcher.new
      OutputHandler::Dispatcher.stub!(:new).and_return(dispatcher)

      @metric = @metric_spec.new_metric
      @metric_spec.stub!(:new_metric).and_return(@metric)
      @metric.should_receive(:collect).with(dispatcher, nil)

      runner = MonitorRunner.new(@ipc)
      runner.run_monitor("/appservers/process_count(unicorn)")
    end
  end
end
