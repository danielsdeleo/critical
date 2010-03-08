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
    
    class ExtendedObject < ExtendableRubyBaseClass
      include CoreExt::Base
    end
  end
end


describe Object do
  it "responds to #criticalize and returns itself" do
    o = Object.new
    o.criticalize.should equal o
  end
  
  describe "when extended by the core extensions" do
    it "stores a report object" do
      o = TestHarness::ExtendedObject.new(:superclass_object)
      o.report = :foo
      o.report.should == :foo
    end
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
  
  it "gives an arbitrary line of a multi-line string counting from zero" do
    co = CriticalString.new("foo\nbar\nbaz")
    co.line(0).should == "foo"
    co.line(1).should == "bar"
    co.line(2).should == "baz"
  end
  
  it "processes itself according to a given regular expression" do
    co = CriticalString.new("123 abc")
    co.fields(/^([\d]+) ([\w]+)$/)[0].should == '123'
    co.fields(/^([\d]+) ([\w]+)$/)[1].should == 'abc'
  end
  
  it "raises an arugment error if you pass a non-regex to fields()" do
    co = CriticalString.new("123 abc")
    lambda {co.fields(:not_a_regex_wtf)}.should raise_error(ArgumentError)
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
    report = OutputHandler::DeferredHandler.new(nil)
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