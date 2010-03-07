require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Proxies::MetricReportProxy do
  before do
    @proxied_object = '123'
    @owner = Class.new(MetricCollector).new
    @proxy = Proxies::MetricReportProxy.new(@proxied_object, @owner)
  end
  
  it "keeps the name of the reported value" do
    @proxy.reported_value_name = :disk_utilization_percentage
    @proxy.reported_value_name.should == :disk_utilization_percentage
  end
  
  it "takes the name of the reported value in the constructor" do
    proxy = Proxies::MetricReportProxy.new(@proxied_object, @owner, :blocks_used)
    proxy.reported_value_name.should == :blocks_used
  end
  
  it "keeps the proxied object as the target" do
    @proxy.target.should equal(@proxied_object)
  end
  
  it "says the object is proxied" do
    @proxy.proxied?.should be_true
  end
  
  it "proxies calls to #report to the owner" do
    report = @owner.report
    @proxy.report.should equal(report)
  end
  
end