require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MonitorCollection do
  before do
    @collection = MonitorCollection.instance
    @collection.reset!
  end
  
  it "is has no monitors after a reset" do
    @collection.should be_empty
  end
  
  describe "adding metrics to the collection" do
    before do
      @metric_class = Class.new(Critical::MetricBase)
      @metric_class.metric_name = :df
      @metric_class.monitors(:filesystem)
      @metric_class.collects { :no_op_for_testing }
      
      @monitor = @metric_class.new
      @monitor.namespace = %w[system disk_utilization]
    end
    
    it "creates a task for each monitor" do
      @collection.push @monitor
      @collection.tasks.should have(1).task
    end
    
    it "stores and finds monitors by fully qualified name" do
      @monitor.default_attribute = '/tmp'
      @collection.push @monitor
      @collection.find("/system/disk_utilization/df(/tmp)").should equal(@monitor)
    end
    
    it "stores multiple monitors in the same namespace if they have different short names" do
      @monitor.default_attribute = '/'
      @collection.push @monitor
      @monitor.default_attribute = '/var'
      @collection.push @monitor
      @collection.find("/system/disk_utilization/df(/)").should equal(@monitor)
      @collection.find("/system/disk_utilization/df(/var)").should equal(@monitor)
    end
    
    it "either replaces a monitor when adding another one with the same name in a namespace" do
      @monitor.default_attribute = "/var"
      monitor1 = @monitor.dup
      monitor2 = @monitor.dup
      @collection.push monitor1
      @collection.push monitor2
      @collection.find("/system/disk_utilization/df(/var)").should equal monitor2
    end
    
    it "gives nil if the monitor cannot be found" do
      @collection.find('df()').should be_nil
    end
    
  end
  
  describe "enumerating over the monitors in the collection" do
    before do
      @metric_class = Class.new(Critical::MetricBase)
      @metric_class.metric_name = :df
      @metric_class.monitors(:filesystem)
      @foo_monitor = @metric_class.new
      @foo_monitor.default_attribute = "foo"
      @bar_monitor = @metric_class.new
      @bar_monitor.default_attribute = "bar"
      @baz_monitor = @metric_class.new
      @baz_monitor.default_attribute = "baz"
      @collection << @foo_monitor << @bar_monitor << @baz_monitor
    end
    
    it "yields the monitors via #each (order preserved on ruby 1.9 only)" do
      monitors = []
      @collection.each { |monitor| monitors << monitor }
      monitors.should include(@foo_monitor, @bar_monitor, @baz_monitor)
    end
    
    it "can be enumerated with other enumerable methods" do
      @collection.should respond_to :detect
      @collection.should respond_to :each_with_index
      @collection.should respond_to :grep
    end
  end
  
end
