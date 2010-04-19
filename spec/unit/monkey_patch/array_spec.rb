require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'critical/monkey_patch/array'

describe Array do

  it "aliases [n] as field(n)" do
    [1,2,3].field(2).should == 3
  end

end