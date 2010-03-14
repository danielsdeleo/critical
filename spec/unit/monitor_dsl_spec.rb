require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module TestHarness
  class MonitorGroupDSLImplementer
    include MonitorGroupDSL
    
    def metric_collection
      @collection ||= []
    end
    
    def add_metric_to_collection(metric)
      metric_collection << metric
    end
    
  end
  
  class MetricCollectorExample
    attr_reader :initialized_with
    def initialize(*args)
      @initialized_with = args
    end
  end
end

describe MonitorGroupDSL do
  before do
    @dsl_user = TestHarness::MonitorGroupDSLImplementer.new
    @metric_collector = TestHarness::MetricCollectorExample
    MonitorGroupDSL.add_metric_collector(:ping, @metric_collector)
  end
  
  it "adds a DSL method for a new metric collector" do
    @dsl_user.should respond_to(:ping)
  end
  
  it "creates a new instance of a class when the DSL method is called" do
    @dsl_user.ping.should be_an_instance_of(@metric_collector)
  end
  
  it "passes the first argument to the DSL method to the initializer of the metric class" do
    @dsl_user.ping(:xx).initialized_with.should == [:xx]
  end
    
  it "adds the metric to the metric collection" do
    metric = @dsl_user.ping(:my_webserver)
    @dsl_user.metric_collection.should include(metric)
  end
end