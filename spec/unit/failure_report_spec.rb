require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FailureReport do
  before do
    @failure_report = FailureReport.new
    @error = StandardError.new("A sample error message")
    @bt = caller(0)
    @error.set_backtrace(@bt)
  end
  
  it "tracks whether there's a failure or not" do
    @failure_report.failed?.should be_false
  end
  
  it "stores annotations for conditions that might cause failure later on" do
    @failure_report.annotate("PossiblePreFail", "something seems fishy"); trace = caller(0)
    @failure_report.annotations.first[:name].should == "PossiblePreFail"
    @failure_report.annotations.first[:message].should == "something seems fishy"
    @failure_report.annotations.first[:stacktrace].should == trace
    @failure_report.failed?.should be_false
  end
  
  it "uses Exceptions for annotations" do
    @failure_report.annotate(@error)
    @failure_report.annotations.first[:name].should == "StandardError"
    @failure_report.annotations.first[:message].should == "A sample error message"
    @failure_report.annotations.first[:stacktrace].should == @bt
  end
  
  it "tracks collection failures" do
    @failure_report.collection_failed!(@error)
    @failure_report.failed?.should be_true
    @failure_report.failed_in.should == :collection
  end
  
  it "tracks processing failures" do
    @failure_report.processing_failed!(@error)
    @failure_report.failed?.should be_true
    @failure_report.failed_in.should == :processing
  end
  
  it "tracks expectation failures" do
    @failure_report.expectation_failed!(@error)
    @failure_report.failed?.should be_true
    @failure_report.failed_in.should == :expectation
  end
  
  it "logs failures to info or warning" do
    pending "i can haz logging class?"
  end
  
  it "logs annotations to debug" do
    pending "i can haz logging class?"
  end
end