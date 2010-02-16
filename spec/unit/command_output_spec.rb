require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CommandOutput do
  
  it "gives the last line of a multi-line string" do
    co = CommandOutput.new("foo\nbar\nbaz")
    co.last_line.should == "baz"
  end
  
  it "processes itself according to a given regular expression" do
    co = CommandOutput.new("123 abc")
    co.fields(/^([\d]+) ([\w]+)$/)[0].should == '123'
    co.fields(/^([\d]+) ([\w]+)$/)[1].should == 'abc'
  end
  
  it "logs an error if the regexp doesn't match when using fields" do
    pending
  end
end