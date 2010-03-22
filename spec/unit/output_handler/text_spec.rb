require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

# describe OutputHandler::TextGroupHandler do
#   before do
#     @output_io = StringIO.new
#     @metric_group = MonitorGroup.new(:disk_checks)
#     
#     @handler = OutputHandler::TextGroupHandler.new(@metric_group, :output_io => @output_io)
#   end
#   
#   it "takes an IO object to print output to in the constructor" do
#     @handler.io.should equal @output_io
#   end
#   
#   it "prints 'Beginning collection on monitor_group[_name_]' when start is called" do
#     @handler.start
#     @output_io.string.should == "Beginning collection on monitor_group[disk_checks]\n"
#   end
#   
#   it "prints 'Completed collection on monitor_group[_name_] when stop is called" do
#     @handler.stop
#     @output_io.string.should == "Completed collection on monitor_group[disk_checks]\n"
#   end
# end
# 
describe OutputHandler::Text do
  before do
    metric_collector_class = Class.new(Critical::Monitor)
    metric_collector_class.metric_name = :disk_io
    metric_collector_class.monitors(:filesystem)
    @metric_collector = metric_collector_class.new("root")
    
    
    @output_io = StringIO.new
    @handler = OutputHandler::Text.new(:output => @output_io)
    @handler.metric = @metric_collector
  end
  
  it_should_behave_like "a metric output handler"
  
  it "takes an IO object to print output to in the constructor" do
    @handler.io.should equal @output_io
  end
  
  it "prints 'collecting metric.to_s' when collection_started is called" do
    @handler.collection_started
    @output_io.string.should == "collecting disk_io(root)\n"
  end
  
  it "doesn't print anything when collection_succeeded is called" do
    @handler.collection_succeeded
    @output_io.string.should == ''
  end
  
  it "doesn't print anything immediately when annotate is called" do
    @handler.annotate("ThisDontLookRight", "but maybe you thought of that already...")
    @output_io.string.should == ''
  end
  
  it "doesn't print anything when collection is completed" do
    @handler.collection_completed
    @output_io.string.should == ''
  end
  
  describe "when a failure occurs" do
    before do
      @exception = StandardError.new("epic failz")
      @bt = caller
      @exception.set_backtrace(@bt)
    end
  
    it "prints the exception when collection fails" do
      @handler.collection_failed(@exception)
      @output_io.string.should match(/^Collection of disk_io\(root\) FAILED/)
      @output_io.string.should match(/StandardError: epic failz/)
    end
  
    it "prints outstanding annotations when collection fails" do
      @handler.annotate("MaybeThisIsWhy", "your codez is broken")
      @handler.collection_failed(@exception)
      @output_io.string.should match(/^Collection of disk_io\(root\) FAILED/)
      @output_io.string.should match(/^Received warning prior to failure:/)
      @output_io.string.should match(/^MaybeThisIsWhy: your codez is broken/)
      @output_io.string.should match(/StandardError: epic failz/)
    end
    
    it "prints the exception when processing fails" do
      @handler.processing_failed(@exception)
      @output_io.string.should match(/^Processing of disk_io\(root\) FAILED/)
      @output_io.string.should match(/StandardError: epic failz/)
    end
    
    it "prints outstanding annotations when processing fails" do
      @handler.annotate("MaybeThisIsWhy", "your codez is broken")
      @handler.processing_failed(@exception)
      @output_io.string.should match(/^Processing of disk_io\(root\) FAILED/)
      @output_io.string.should match(/^Received warning prior to failure:/)
      @output_io.string.should match(/^MaybeThisIsWhy: your codez is broken/)
      @output_io.string.should match(/StandardError: epic failz/)
    end
    
    it "prints the explanation when an expectation fails" do
      @handler.expectation_failed(@exception)
      @output_io.string.should match(/^Expectation on disk_io\(root\) FAILED/)
      @output_io.string.should match(/StandardError: epic failz/)
    end
    
    it "prints outstanding annotations when an expectation fails" do
      @handler.annotate("MaybeThisIsWhy", "your codez is broken")
      @handler.expectation_failed(@exception)
      @output_io.string.should match(/^Expectation on disk_io\(root\) FAILED/)
      @output_io.string.should match(/^Received warning prior to failure:/)
      @output_io.string.should match(/^MaybeThisIsWhy: your codez is broken/)
      @output_io.string.should match(/StandardError: epic failz/)
    end
    
    it "prints a message when an expectation succeeds" do
      @handler.expectation_succeeded("ExpectationSucceeded", "expected true to be true and wow, it is!")
      @output_io.string.split("\n").first.should == "Expectation on disk_io(root) succeeded"
      @output_io.string.split("\n").last.should == "ExpectationSucceeded: expected true to be true and wow, it is!"
    end
    
  end
end