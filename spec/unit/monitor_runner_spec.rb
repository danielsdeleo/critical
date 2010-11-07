require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MonitorRunner do
  before do
    MonitorCollection.instance.reset!
    @monitor = Critical::Monitor.new
    @monitor.fqn = "/appservers/process_count(unicorn)"
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
