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
      @metric_class = Class.new(Critical::Monitor)
      @metric_class.metric_name = :df
      @metric_class.monitors(:filesystem)
      @metric_class.collects { :no_op_for_testing }
      
      @monitor = @metric_class.new
    end
    
    it "creates a task for each monitor" do
      @collection.push @monitor
      @collection.tasks.should have(1).task
    end
    
    it "stores and finds monitors by fully qualified name" do
      @monitor.fqn = "/unix_boxes/disks/df(/tmp)"
      @collection.push @monitor
      @collection.find("/unix_boxes/disks/df(/tmp)").should equal(@monitor)
    end
    
    it "stores multiple monitors in the same namespace if they have different short names" do
      @monitor.fqn = "/unix_boxes/disks/df(/)"
      @collection.push @monitor
      @monitor.fqn = "/unix_boxes/disks/df(/var)"
      @collection.push @monitor
      @collection.find("/unix_boxes/disks/df(/)").should equal(@monitor)
      @collection.find("/unix_boxes/disks/df(/var)").should equal(@monitor)
    end
    
    it "either replaces a monitor when adding another one with the same name in a namespace" do
      @monitor.fqn = "/unix_boxes/disks/df(/var)"
      monitor1 = @monitor.dup
      monitor2 = @monitor.dup
      @collection.push monitor1
      @collection.push monitor2
      @collection.find("/unix_boxes/disks/df(/var)").should equal monitor2
    end
    
    it "gives nil if the monitor cannot be found" do
      @collection.find('df()').should be_nil
    end
    
  end
  
end