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

  describe "when configured for continuous mode" do
    before do
      Application::Configuration.instance.continuous
    end

    it "runs in continuous mode after setting up" do
      Application::Configuration.should_receive(:configure!)
      Application::Configuration.instance.source_files << '/tmp/foo.rb' << '/tmp/bar.rb'
      FileLoader.should_receive(:load_metrics_and_monitors_in).with("/tmp/foo.rb")
      FileLoader.should_receive(:load_metrics_and_monitors_in).with("/tmp/bar.rb")

      Application::Configuration.instance.should_receive(:validate_configuration!)

      @main.should_receive(:run_continous)

      @main.run
    end

    it "sets up process and signal management, then enters the main loop" do
      Application::Configuration.instance.daemonize
      Application::Daemon.should_receive(:daemonize)

      [:QUIT, :INT, :TERM, :USR1, :USR2, :HUP ].each do |sig|
        @main.should_receive(:trap).with(sig)
      end

      ProcessManager.instance.should_receive(:start_ipc)
      ProcessManager.instance.should_receive(:spawn_worker)
      ProcessManager.instance.should_receive(:manage_workers)

      Application::Main::ACTION_QUEUE << nil << :QUIT

      @main.scheduler.stub!(:time_until_next_task).and_return(0)

      @main.run_continous
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
      (Time.now - start).should be_within(1).of(0)
    end

    it "runs the scheduler" do
      scheduler = mock("Scheduler", :time_until_next_task => 5)
      @main.stub!(:scheduler).and_return(scheduler)
      @main.should_receive(:sleep).and_return(nil)
      Application::Main::ACTION_QUEUE << nil

      scheduler.should_receive(:each)
      @main.enqueue_monitor_tasks

      Application::Main::ACTION_QUEUE << :QUIT

      scheduler.should_receive(:each)
      @main.run_main_loop
    end
  end

  describe "when not configured for continuous mode" do
    before do
      Application::Configuration.instance.should_not be_continuous
    end

    it "runs in single run mode after setting up" do
      Application::Configuration.should_receive(:configure!)
      Application::Configuration.instance.source_files << '/tmp/foo.rb' << '/tmp/bar.rb'
      FileLoader.should_receive(:load_metrics_and_monitors_in).with("/tmp/foo.rb")
      FileLoader.should_receive(:load_metrics_and_monitors_in).with("/tmp/bar.rb")

      Application::Configuration.instance.should_receive(:validate_configuration!)

      @main.should_receive(:run_single)

      @main.run
    end

    it "passes each of the monitors to a monitor runner and exits" do
      monitor_task_1 = Scheduler::Task.new("monitor_task_1", 1,nil)
      monitor_task_2 = Scheduler::Task.new("monitor_task_2", 1,nil)

      @main.scheduler.schedule(monitor_task_1)
      @main.scheduler.schedule(monitor_task_2)

      @main.runner.method(:run_monitor).arity.should == 1
      @main.runner.should_receive(:run_monitor).with("monitor_task_1")
      @main.runner.should_receive(:run_monitor).with("monitor_task_2")

      @main.run_single
    end

  end

end

