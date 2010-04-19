require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'critical/monkey_patch/string'

describe String do

  it "gives the last line of a multi-line string" do
    "foo\nbar\nbaz".last_line.should == "baz"
  end

  it "gives an arbitrary line of a multi-line string strunting from zero" do
    str = "foo\nbar\nbaz"
    str.line(0).should == "foo"
    str.line(1).should == "bar"
    str.line(2).should == "baz"
  end

  it "processes itself acstrrding to a given regular expression" do
    str = "123 abc"
    str.fields(/^([\d]+) ([\w]+)$/)[0].should == '123'
    str.fields(/^([\d]+) ([\w]+)$/)[1].should == 'abc'
  end

  it "raises an arugment error if you pass a non-regex to fields()" do
    lambda {"123 abc".fields(:not_a_regex_wtf)}.should raise_error(ArgumentError)
  end

end
