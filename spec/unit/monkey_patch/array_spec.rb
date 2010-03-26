require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'critical/monkey_patch/array'

describe Array do
  
  it "aliases [n] as field(n)" do
    [1,2,3].field(2).should == 3
  end
  
  it "preserves its report object in the output of customized methods" do
    ary = [1,2,3]
    ary.critical_error_report = :report_obj
    ary.field(1).critical_error_report.should == :report_obj
  end
  
end