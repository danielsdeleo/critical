require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe DSL::TopLevel do
  
  it "implements the Metric DSL" do
    Critical::DSL::TopLevel.should respond_to(:Metric)
  end
  
  it "implements the Monitor method, proxying to the monitor collection instance" do
    Critical::MonitorCollection.instance.should_receive(:Monitor).with(:foodz)
    Critical::DSL::TopLevel.Monitor(:foodz)
  end
  
end