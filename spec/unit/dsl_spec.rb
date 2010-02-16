require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module TestHarness
  class MonitorGroupDSLImplementer
    include MonitorGroupDSL
  end
end

describe DSL do
  
  describe "defining new metrics" do
    before do
      @value_in_closure = nil
      @new_metric = DSL.Metric(:squishiness) do |squishiness|
        @value_in_closure = squishiness
      end
    end
    
    it "creates a new metric collector class" do
      @new_metric.should be_an_instance_of(Class)
      @new_metric.should < MetricCollector
      @new_metric.should == @value_in_closure
    end
    
    it "sets the metric name on the collector class" do
      @new_metric.metric_name.should == :squishiness
    end

    it "adds the new metric collector class to the monitor group dsl" do
      TestHarness::MonitorGroupDSLImplementer.new.should respond_to(:squishiness)
    end
  end
  
  describe "defining monitor groups" do
    
    it "creates a new monitor group" do
      monitor_group = DSL.Monitor(:developer_laptop) do |laptop|
      end
      
      monitor_group.should be_an_instance_of(MonitorGroup)
      monitor_group.name.should == :developer_laptop
    end
    
    it "passes a given block to the monitor group's initializer" do
      name = nil
      monitor_group = DSL.Monitor(:developer_laptop) do |laptop|
        name = laptop.name
      end
      name.should == :developer_laptop
    end
    
    it "collects the monitor group into some global collection I haven't conceived yet" do
      pending :obviously
    end
  end
  
end