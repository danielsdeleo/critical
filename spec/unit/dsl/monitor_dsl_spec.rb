require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module TestHarness
  class MonitorDSLImplementer
    include DSL::MonitorDSL
    
    def metric_collection
      @collection ||= []
    end
    
    def push(metric)
      metric_collection << metric
    end
    
  end
  
  class MonitorExample < MetricBase
    def self.metric_name
      :df
    end
  end
end

describe MetricSpecification do

  before do
    @metric_processing_block = lambda { :processing_block }
    @namespace = [:foo, "bar", :baz]
    @metric_spec = MetricSpecification.new(TestHarness::MonitorExample, "/tmp", @namespace, @metric_processing_block)
  end

  it "has a namespace" do
    @metric_spec.namespace.should == [:foo, "bar", :baz]
  end

  it "generates a fully qualified name from its namespace" do
    @metric_spec.fqn.should == "/foo/bar/baz/df(/tmp)"
  end

  it "initializes a new metric" do
    metric = @metric_spec.new_metric
    metric.processing_block.call.should == :processing_block
    metric.namespace.should == [:foo, "bar", :baz]
    metric.fqn.should == "/foo/bar/baz/df(/tmp)"
  end

end

describe DSL::MonitorDSL do
  before do
    @dsl_user = TestHarness::MonitorDSLImplementer.new
    @metric = TestHarness::MonitorExample
    Critical::DSL::MonitorDSL.define_metric(:ping, @metric)
  end
  
  it "adds a DSL method for a new metric collector" do
    @dsl_user.should respond_to(:ping)
  end
  
  it "creates a metric specification when the metric method is called" do
    #@dsl_user.ping.should be_an_instance_of(@metric)
    @dsl_user.ping.should be_an_instance_of(MetricSpecification)
  end
  
  it "adds the first argument to the metric specification" do
    @dsl_user.ping(:xx).default_attribute.should == :xx
  end

  it "passes the block to the metric specification" do
    block = lambda { :hello }
    @dsl_user.ping(:xx, &block).processing_block.call.should == :hello
  end

  it "sets the current namespace on the metric specification" do
    @dsl_user.namespace.concat [:system, :HOSTNAME]
    @dsl_user.ping(:xx).namespace.should == [:system, :HOSTNAME]
  end

  it "sets the corresponding MetricBase class on the metric specification" do
    @dsl_user.ping(:xx).metric_class.should equal(TestHarness::MonitorExample)
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
      lambda {@dsl_user.Monitor("foo/bar")}.should raise_error(InvalidNamespace)
    end

    it "allows the - character in namespaces (for hostnames)" do
      lambda {@dsl_user.Monitor("foo-bar")}.should_not raise_error(InvalidNamespace)
    end

    it "raises an error when attempting to create a namespace with a non-string or symbol object" do
      subclassing_string_works = Class.new(String).new("foobar")
      lambda {@dsl_user.Monitor(subclassing_string_works){}}.should_not raise_error
      lambda {@dsl_user.Monitor(Range.new(2,5))}.should raise_error(InvalidNamespace)
      # Fixnum#to_sym is pretty much guaranteed to be really confusing, so it is also banned:
      lambda {@dsl_user.Monitor(123)}.should raise_error(InvalidNamespace)
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
    
    it "gives the current namespace as a string" do
      namespace_str = nil
      @dsl_user.Monitor(:unix_boxes) do
        Monitor(:disks) do
          namespace_str = current_namespace
        end
      end
      namespace_str.should == "/unix_boxes/disks"
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
    
    it "sets a monitor's namespace" do
      monitor = nil
      @dsl_user.Monitor(:network) do
        monitor = monitor
        Monitor(:routers) do
          monitor = ping("the_core_router")
        end
      end
      monitor.namespace.should == [:network, :routers]
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
