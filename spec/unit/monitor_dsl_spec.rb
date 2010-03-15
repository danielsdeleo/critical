require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module TestHarness
  class MonitorDSLImplementer
    include MonitorDSL
    
    def metric_collection
      @collection ||= []
    end
    
    def push(metric)
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

describe MonitorDSL do
  before do
    @dsl_user = TestHarness::MonitorDSLImplementer.new
    @metric_collector = TestHarness::MetricCollectorExample
    MonitorDSL.define_metric(:ping, @metric_collector)
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
  
  describe "defining monitors" do
    it "defaults to no namespace" do
      @dsl_user.namespace.should == []
    end
    
    it "raises an error when attempting to create a namespace with an invalid char" do
      lambda {@dsl_user.Monitor("foo/bar")}.should raise_error(MonitorDSL::InvalidNamespace)
    end
    
    it "raises an error when attempting to create a namespace with a non-string or symbol object" do
      subclasses_are_cool = Class.new(String).new("foobar")
      lambda {@dsl_user.Monitor(subclasses_are_cool){}}.should_not raise_error
      lambda {@dsl_user.Monitor(Range.new(2,5))}.should raise_error(MonitorDSL::InvalidNamespace)
      # Fixnum#to_sym is pretty much guaranteed to be really confusing, so it is also banned:
      lambda {@dsl_user.Monitor(123)}.should raise_error(MonitorDSL::InvalidNamespace)
    end
    
    it "has nested namespacing with blocks" do
      snitch = nil
      @dsl_user.Monitor(:unix_hosts) do
        namespace.should == [:unix_hosts]
        Monitor(:disks) do
          snitch = :snitchy
          namespace.should == [:unix_hosts, :disks]
        end
        namespace.should == [:unix_hosts]
      end
      @dsl_user.namespace.should == []
      snitch.should == :snitchy
    end
    
    it "yields itself to blocks with arity of one" do
      snitch = nil
      @dsl_user.Monitor(:unix_hosts) do |unix_hosts|
        unix_hosts.should equal(@dsl_user)
        unix_hosts.Monitor(:disks) do |disks|
          snitch = :yep
          disks.should equal(@dsl_user)
        end
      end
      snitch.should == :yep
    end
    
    it "sets the interval" do
      snitch = nil
      @dsl_user.every(10 => :minutes) do
        @interval.should == 600
        
        every(5 => :minutes) do
          @interval.should == 300
          snitch = :yep
        end
        @interval.should == 600
      end
      snitch.should == :yep
    end
    
    it "sets the interval in non-block fashion" do
      @dsl_user.Monitor(:lolz) do
        collect_every(2 => :min)
        @interval.should == 120
      end
    end
    
  end
  
end