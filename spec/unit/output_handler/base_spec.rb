require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module Critical
  module TestHarness
    class OutputHandlerWithStartStopTripwires < OutputHandler::GroupBaseHandler
      attr_reader :start_called, :stop_called, :constructor_opt, :setup_args
      def start
        @start_called = true
      end
      
      def stop
        @stop_called = true
      end
      
      def setup(opts={})
        @constructor_opt = opts[:mine]
        @setup_args = opts
      end
    end
  end
end

describe OutputHandler::GroupBaseHandler do
  before do
    @metric_group = MonitorGroup.new(:disk_checks)
    @handler = OutputHandler::GroupBaseHandler.new(@metric_group, :option1 => :foo, :mine => :bar)
  end
  
  it "takes a mandatory metric_group argument and an optional option hash in the constructor" do
    @handler.metric_group.should equal @metric_group
  end
  
  it "provides a hook for subclasses to get options they are interested in from the options hash" do
    handler = TestHarness::OutputHandlerWithStartStopTripwires.new(@metric_group, :mine => :all_mine)
    handler.constructor_opt.should == :all_mine
  end
  
  it "calls start, yields itself, then calls stop when created with a block" do
    handler = TestHarness::OutputHandlerWithStartStopTripwires.new(@metric_group) do |o|
      o.start_called.should be_true
    end
    handler.stop_called.should be_true
  end
  
  it "receives :start when a collection run begins" do
    @handler.should respond_to :start
  end
  
  it "receives :stop when a collection run is completed" do
    @handler.should respond_to :stop
  end
  
  it "raises an error with a descriptive message if no handler for individual metrics has been defined" do
    handler_class = Class.new(OutputHandler::GroupBaseHandler)
    handler = handler_class.new(@metric_group, :option => :foo)
    lambda {handler.metric_report}.should raise_error(Critical::NotImplementedError)
  end
  
  it "makes a hash of :symbol_of_snake_cased_class_name => ClassNameConst when subclassed" do
    actual = OutputHandler::GroupBaseHandler.symbol_to_handler[:output_handler_with_start_stop_tripwires]
    actual.should equal(TestHarness::OutputHandlerWithStartStopTripwires)
  end
end

describe OutputHandler::MetricBaseHandler do  
  before do
    @handler = OutputHandler::MetricBaseHandler.new
  end
  
  it_should_behave_like "a metric output handler"
end