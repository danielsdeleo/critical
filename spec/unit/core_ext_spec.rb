require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class ExtendableRubyBaseClass
  def initialize(value)
    @value = value
  end
end

module Critical
  module TestHarness
    class ExtensionToBaseClass < ExtendableRubyBaseClass
      extend CoreExt::Base::ClassMethods
    end
  end
end


describe Object do
  it "responds to #criticalize and returns itself" do
    o = Object.new
    o.criticalize.should equal o
  end
end

describe CoreExt::Base::ClassMethods do
  it "defines a custom criticalize method on the core class" do
    TestHarness::ExtensionToBaseClass.extends_class(ExtendableRubyBaseClass)
    ExtendableRubyBaseClass.new(:foo).criticalize.should be_an_instance_of(TestHarness::ExtensionToBaseClass)
  end
end

describe CriticalString do
  
  it "gives the last line of a multi-line string" do
    co = CriticalString.new("foo\nbar\nbaz")
    co.last_line.should == "baz"
  end
  
  it "processes itself according to a given regular expression" do
    co = CriticalString.new("123 abc")
    co.fields(/^([\d]+) ([\w]+)$/)[0].should == '123'
    co.fields(/^([\d]+) ([\w]+)$/)[1].should == 'abc'
  end
  
  it "stores a report object" do
    co = CriticalString.new("123")
    co.report = :foo
    co.report.should == :foo
  end
  
  it "can be initialized with a report object" do
    co = CriticalString.new("123abc", :a_report_object)
    co.report.should == :a_report_object
  end
  
  it "preserves the report object when returning a new command output object" do
    co = CriticalString.new("123\nabc", :a_report_obj)
    co.last_line.report.should == :a_report_obj
  end
  
  it "logs an error if the regexp doesn't match when using fields" do
    report = CollectionReport.new(nil)
    co = CriticalString.new("something_unexpected", report)
    co.fields(/^[\d]+$/)
    err = co.report.errors.first
    err[:name].should == "Regexp Match Failure"
    err[:message].should == 'Could not parse fields from "something_unexpected" with regexp /^[\\d]+$/'
  end
end

describe CriticalArray do
  
  it "aliases [n] as field(n)" do
    [1,2,3].criticalize.field(2).should == 3
  end
  
end