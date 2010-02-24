require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CollectionReport do
  before do
    metric_collector_class = Class.new(MetricCollector)
    metric_collector_class.metric_name = :disk_io
    metric_collector_class.monitors(:filesystem)
    @metric_collector = metric_collector_class.new
    @collection_report = CollectionReport.new(@metric_collector)
    
    @error = StandardError.new("A sample error message")
    @bt = caller(0)
    @error.set_backtrace(@bt)
  end
  
  it "tracks whether there's a failure or not" do
    @collection_report.failed?.should be_false
  end
  
  it "stores errors for conditions that might cause failure later on" do
    @collection_report.annotate("PossiblePreFail", "something seems fishy"); trace = caller(0)
    @collection_report.errors.first[:name].should == "PossiblePreFail"
    @collection_report.errors.first[:message].should == "something seems fishy"
    @collection_report.errors.first[:stacktrace].should == trace
    @collection_report.failed?.should be_false
  end
  
  it "uses Exceptions for errors" do
    @collection_report.annotate(@error)
    @collection_report.errors.first[:name].should == "StandardError"
    @collection_report.errors.first[:message].should == "A sample error message"
    @collection_report.errors.first[:stacktrace].should == @bt
  end
  
  it "tracks collection failures" do
    @collection_report.collection_failed!(@error)
    @collection_report.failed?.should be_true
    @collection_report.failed_in.should == :collection
  end
  
  it "tracks processing failures" do
    @collection_report.processing_failed!(@error)
    @collection_report.failed?.should be_true
    @collection_report.failed_in.should == :processing
  end
  
  it "tracks expectation failures" do
    @collection_report.expectation_failed!(@error)
    @collection_report.failed?.should be_true
    @collection_report.failed_in.should == :expectation
  end
  
  it "stores the data collection time" do
    now = Time.new
    @collection_report.collected_at = now
    @collection_report.collected_at.should == now
  end
  
  it "keeps collected data" do
    @collection_report.collected("root disk percentage", 91)
    @collection_report.data.should == {"root disk percentage" => 91}
  end
  
  it "converts to a hash" do
    @collection_report.annotate("PossiblePreFail", "something seems fishy"); trace = caller(0)
    @collection_report.processing_failed!(@error)
    now = @collection_report.collected_at = Time.new
    report_as_hash = @collection_report.to_hsh
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
    @collection_report.annotate("PossiblePreFail", "something seems fishy"); trace = caller(0)
    @collection_report.to_hsh[:errors].should == []
    @collection_report.to_hsh[:metric_source_line].should be_nil
  end
  
  it "logs failures to info or warning" do
    # leaving this here just so's I remember
    pending "actually, no. instead, have the runner pass collection reports to formatters"
  end
  
end