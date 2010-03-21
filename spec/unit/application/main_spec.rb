require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Application::Main do
  before do
    @main = Application::Main.new
  end
  
  it "loads metrics from files"
  it "loads monitor definitions from files"
  it "loads a configuration file"
  
  it "daemonizes the application" do
    Application::Daemon.should_receive(:daemonize)
    @main.daemonize!
  end
  
  it "runs the scheduler"
  it "runs the executor"
end

