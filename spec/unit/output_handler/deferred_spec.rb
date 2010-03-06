require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe OutputHandler::DeferredHandler do
  before do
    metric_collector_class = Class.new(MetricCollector)
    metric_collector_class.metric_name = :disk_io
    metric_collector_class.monitors(:filesystem)
    @metric_collector = metric_collector_class.new
    @handler = OutputHandler::DeferredHandler.new(@metric_collector)
    
    @error = StandardError.new("A sample error message")
    @bt = caller(0)
    @error.set_backtrace(@bt)
  end
  
  it_should_behave_like "a metric output handler"
  
  it "tracks whether there's a failure or not" do
    @handler.failed?.should be_false
  end
  
  it "stores errors for conditions that might cause failure later on" do
    @handler.annotate("PossiblePreFail", "something seems fishy"); trace = caller(0)
    @handler.errors.first[:name].should == "PossiblePreFail"
    @handler.errors.first[:message].should == "something seems fishy"
    (@handler.errors.first[:stacktrace] & trace).should == trace
    @handler.failed?.should be_false
  end
  
  it "uses Exceptions for errors" do
    @handler.annotate(@error)
    @handler.errors.first[:name].should == "StandardError"
    @handler.errors.first[:message].should == "A sample error message"
    @handler.errors.first[:stacktrace].should == @bt
  end
  
  it "tracks collection failures" do
    @handler.collection_failed(@error)
    @handler.failed?.should be_true
    @handler.failed_in.should == :collection
  end
  
  it "tracks processing failures" do
    @handler.processing_failed(@error)
    @handler.failed?.should be_true
    @handler.failed_in.should == :processing
  end
  
  it "tracks expectation failures" do
    @handler.expectation_failed(@error)
    @handler.failed?.should be_true
    @handler.failed_in.should == :expectation
  end
  
  it "stores the data collection time" do
    now = Time.new
    @handler.collected_at = now
    @handler.collected_at.should == now
  end
  
  it "keeps collected data" do
    @handler.collected("root disk percentage", 91)
    @handler.data.should == {"root disk percentage" => 91}
  end
  
  it "converts to a hash" do
    trace = caller(0)
    @handler.annotate("PossiblePreFail", "something seems fishy", trace)
    @handler.processing_failed(@error)
    now = @handler.collected_at = Time.new
    report_as_hash = @handler.to_hsh
    report_as_hash[:errors].should be_an(Array)
    report_as_hash[:errors].first.should == { :name => "PossiblePreFail", 
                                              :message => "something seems fishy", 
                                              :stacktrace => trace}
    report_as_hash[:errors].last.should == {:name => @error.class.name, :message => @error.message, :stacktrace => @bt}
    report_as_hash[:failed].should == true
    report_as_hash[:metric].should == @metric_collector.metadata
    report_as_hash[:metric_source_line].should == @metric_collector.creator_line
    report_as_hash[:collected_at].should == now
  end
  
  it "lies and gives :errors as an empty array in #to_hsh when collection/processing/expectations don't fail" do
    @handler.annotate("PossiblePreFail", "something seems fishy"); trace = caller(0)
    @handler.to_hsh[:errors].should == []
    @handler.to_hsh[:metric_source_line].should be_nil
  end
  
end