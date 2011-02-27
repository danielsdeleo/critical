require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MonitorRunner do
  before do
    MonitorCollection.instance.reset!
    @metric_class = Class.new(Critical::Monitor)
    @metric_class.metric_name = :process_count
    @metric_class.monitors(:processes_by_name)
    @monitor = @metric_class.new("unicorn")
    
    @monitor.namespace = %w[appservers]
    puts @monitor.fqn
    MonitorCollection.instance.push(@monitor)

    @ipc = ProcessManager::IPCData.new(nil, nil)
  end

  it "holds a copy of its IPC instructions" do
    runner = MonitorRunner.new(@ipc)
    runner.ipc.should equal(@ipc)
  end

  it "looks up a monitor in the collection" do
    @monitor.should_receive(:collect)
    runner = MonitorRunner.new(@ipc)
    runner.run_monitor("/appservers/process_count(unicorn)")
  end

end
