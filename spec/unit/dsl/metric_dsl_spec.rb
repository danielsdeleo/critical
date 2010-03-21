require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module TestHarness
  class MonitorDSLImplementer
    include DSL::MonitorDSL
  end
end

describe DSL::MetricDSL do
  
  describe "defining new metrics" do
    before do
      @value_in_closure = nil
      @new_metric = Critical::DSL::MetricDSL.Metric(:squishiness) do |squishiness|
        @value_in_closure = squishiness
      end
    end
    
    it "creates a new metric collector class" do
      @new_metric.should be_an_instance_of(Class)
      @new_metric.should < Critical::Monitor
      @new_metric.should == @value_in_closure
    end
    
    it "sets the metric name on the collector class" do
      @new_metric.metric_name.should == :squishiness
    end

    it "adds the new metric collector class to the monitor group dsl" do
      TestHarness::MonitorDSLImplementer.new.should respond_to(:squishiness)
    end
    
    it "assigns the metric to a constant so it has a useful name" do
      Critical::Metrics::Squishiness.should == @new_metric
    end
  end
  
end
