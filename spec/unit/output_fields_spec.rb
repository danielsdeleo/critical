require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OutputFields do
  
  it "aliases [n] as field(n)" do
    OutputFields.new([1,2,3]).field(2).should == 3
  end
  
end