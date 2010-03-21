require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MonitorRunner do
  
  it "takes a queue in the initializer" do
    @queue = Queue.new
    runner = MonitorRunner.new(@queue)
    runner.queue.should equal(@queue)
  end
  
  it "looks up a monitor in the collection"
  
end
