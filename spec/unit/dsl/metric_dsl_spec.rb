require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module TestHarness
  class MonitorDSLImplementer
    include DSL::MonitorDSL
  end
end

describe DSL::MetricDSL do
  
  describe "defining new metrics" do
    before do
      original_verbose = $VERBOSE
      $VERBOSE = nil # yes, I know I'm redefining constant blah blah blah
      begin
        value_in_closure = nil
        @new_metric = Critical::DSL::MetricDSL.Metric(:squishiness) do
          value_in_closure = self
        
          def this_should_be_an_instance_method
          end
        end
        @value_in_closure = value_in_closure
      ensure
        $VERBOSE = original_verbose # but warnings are good in general
      end
    end
    
    it "creates a new metric collector class" do
      @new_metric.should be_an_instance_of(Class)
      @new_metric.should < Critical::MetricBase
    end
    
    it "evaluates the block as a class body" do
      @value_in_closure.should == Critical::Metrics::Squishiness
      @new_metric.new(nil).should respond_to(:this_should_be_an_instance_method)
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
