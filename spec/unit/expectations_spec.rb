require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Critical
  module TestHarness
    class Expector
      attr_accessor :report
      include Expectations::Expectable
    end
    
    class Matchy
      include Expectations::Matchers
    end
  end
end

describe Expectations::Expectable do
  before do
    @expector = TestHarness::Expector.new
    @report = @expector.report = CollectionReport.new(nil)
  end
  
  it "requires access to a report object but doesn't implement this API itself" do
    naked_class = Class.new
    naked_class.send(:include, Expectations::Expectable)
    expector = naked_class.new
    lambda {expector.report}.should raise_error(Critical::NotImplementedError)
  end
  
  it "returns self for the target by default" do
    @expector.target.should equal @expector
  end
  
  it "matches against the value of #target" do
    def @expector.target
      :foo
    end
    @expector.is(:block => lambda { |arg| arg == :foo }).should be_true
  end
  
  it "takes a block, calls it, and succeeds if the block returns true" do
    no_cheating = false
    @expector.is(:name=>'rspec example',:arg=>23,:block=>lambda { |arg| no_cheating = true })
    no_cheating.should be_true
    @report.failed?.should be_false
  end
  
  it "fails if the block does not return true" do
    @expector.is(:name=>"somewhat like", :arg=>"unpossible", :block=>lambda {|arg| "untrue"})
    @report.failed?.should be_true
    @report.failed_in.should == :expectation
    err = @report.errors.first
    pending "is the failure message a pre-formatted string, or a hash of values that can be formatted by a formatter?"
    err[:message].should == "expected"
  end
  
  it "aliases #is as #should_be" do
    @expector.should respond_to(:should_be)
  end
end

describe Expectations::Matchers do
  before do
    @matching = TestHarness::Matchy.new
  end  
  
  it "creates expectations for exact matches" do
    matcher = @matching.exactly("foo")
    matcher[:name].should == "exactly"
    matcher[:arg].should == "foo"
    matcher[:block].call("foo").should be_true
    matcher[:block].call("bar").should be_false
  end
  
  it "creates expectations for lesser or equal" do
    matcher = @matching.lte(5)
    matcher[:name].should == "less than or equal to"
    matcher[:arg].should == 5
    matcher[:block].call(5).should be_true
    matcher[:block].call(4.5).should be_true
    matcher[:block].call(5.1).should be_false
  end
  
  it "creates expectations for greater or equal" do
    matcher = @matching.gte(5)
    matcher[:name].should == "greater than or equal to"
    matcher[:arg].should == 5
    matcher[:block].call(5).should be_true
    matcher[:block].call(4.5).should be_false
    matcher[:block].call(5.1).should be_true
  end
  
end