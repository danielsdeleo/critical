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

  it "selects on its self_pipe with a given timeout" do
    IO.should_receive(:select).with([an_instance_of(IO)], nil,nil , 10)
    @main.init_self_pipe
    @main.sleep(10)
  end

  it "wakes up from a sleep" do
    start = Time.now
    @main.init_self_pipe
    @main.awaken
    @main.sleep(10)
    (Time.now - start).should be_close(0, 1)
  end

  it "runs the scheduler" do
    scheduler = mock("Scheduler", :time_until_next_task => 5)
    @main.stub!(:scheduler).and_return(scheduler)
    @main.should_receive(:sleep).and_return(true)
    Application::Main::ACTION_QUEUE << nil

    scheduler.should_receive(:each)
    @main.enqueue_monitor_tasks

    Application::Main::ACTION_QUEUE << :QUIT

    scheduler.should_receive(:each)
    @main.run_main_loop
  end
  
end

