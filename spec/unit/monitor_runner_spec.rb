require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MonitorRunner do
  before do
    MonitorCollection.instance.reset!
    @monitor = Critical::Monitor.new
    @monitor.fqn = "/appservers/process_count(unicorn)"
    MonitorCollection.instance.push(@monitor)
  end

  it "takes a queue in the initializer" do
    @queue = Queue.new
    runner = MonitorRunner.new(@queue)
    runner.queue.should equal(@queue)
  end

  it "looks up a monitor in the collection" do
    @queue = ["/appservers/process_count(unicorn)"]
    @monitor.should_receive(:collect)
    runner = MonitorRunner.new(@queue)
    runner.run
  end

end
