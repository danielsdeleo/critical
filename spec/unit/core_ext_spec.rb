require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class ExtendableRubyBaseClass
  def initialize(value)
    @value = value
  end
end

describe Object do
  
  it "stores a report object" do
    o = Object.new
    o.critical_error_report = :foo
    o.critical_error_report.should == :foo
  end
  
end
