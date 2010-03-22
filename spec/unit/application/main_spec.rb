require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Application::Main do
  before do
    Application::Configuration.instance.reset!
    @main = Application::Main.new
  end
  
  it "loads metric and monitor sources" do
    $loaded_in_context_of = nil
    Critical.config.require File.dirname(__FILE__) + '/../../fixtures/file_loader/file_loader_context_spy'
    @main.load_sources
    $loaded_in_context_of.should_not be_nil
  end
  
  it "sets traps for sigterm, sigint, and HUP" do
    Kernel.should_receive(:trap).with("HUP")
    Kernel.should_receive(:trap).with("INT")
    Kernel.should_receive(:trap).with("TERM")
    @main.trap_signals
  end
  
  it "daemonizes the application" do
    Application::Daemon.should_receive(:daemonize)
    @main.daemonize!
  end
  
  it "runs the scheduler" do
    scheduler = mock("Scheduler::TaskList")
    @main.stub!(:scheduler).and_return(scheduler)
    scheduler.should_receive(:run)
    @main.start_scheduler
  end
  
  it "runs the monitor_runner"
end

