require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MonitorGroup do
  before do
    @monitor_group = MonitorGroup.new(:rspec_examples)
  end
  
  it "implements the monitor group DSL" do
    MonitorGroup.should include(MonitorGroupDSL)
  end
  
  it "has a name" do
    @monitor_group.name.should == :rspec_examples
  end
  
  it "keeps a collection of metrics" do
    @monitor_group.add_metric_to_collection('a metric')
    @monitor_group.metric_collection.should include('a metric')
  end
  
  it "passes itself into a block given to initialize" do
    monitor_group = MonitorGroup.new(:block_arity_1_example) do |mg|
      mg.instance_variable_set(:@snitch, :booyah_achieved)
    end
    monitor_group.instance_variable_get(:@snitch).should == :booyah_achieved
  end
  
  it "instance evals a block given to initialize if the block has arity 0" do
    monitor_group = MonitorGroup.new(:block_arity_0_example) do
      instance_variable_set(:@snitch, :booyah_activated)
    end
    monitor_group.instance_variable_get(:@snitch).should == :booyah_activated
  end
  
  describe "with metrics in the collection" do
    
    before do
      @metric_collector = Class.new(MetricCollector)
      @metric_collector.collects { :foo }
    end

    it "collects all of the metrics in its metric_collection" do
      spy_variable = nil
      metric = @metric_collector.new {spy_variable = :collection_completed; puts "running" }
      @monitor_group.add_metric_to_collection(metric)
      
      @monitor_group.collect_all
      spy_variable.should == :collection_completed
    end
    
  end
  
end