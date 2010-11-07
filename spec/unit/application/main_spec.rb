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
  
  it "daemonizes the application" do
    Application::Daemon.should_receive(:daemonize)
    @main.daemonize!
  end
  
  it "runs the scheduler" do
    scheduler = mock("Scheduler::TaskList", :time_until_next_task => 5)
    scheduler.should_receive(:each)
    @main.stub!(:scheduler).and_return(scheduler)
    ProcessManager.instance.should_receive(:sleep).and_return(true)
    @main.start_scheduler_loop
  end
  
end

