require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module TestHarness
  extend RSpec::Matchers

  class Worker
    include Critical::Subprocess
  end

  def self.test_in_subprocess
    child = fork do
      begin
        yield
        exit!(0)
      rescue Exception => e
        STDERR.puts("#{e.class}: #{e.message}")
        STDERR.puts(e.backtrace.join("\n"))
        exit!(42)
      end
    end
    _, status = Process.waitpid2(child)
    status.should be_success
  end

end

describe ProcessManager do
  before do
    @manager = ProcessManager.instance
    @manager.reset
  end

  after do
    socket = "/tmp/critical-sock.#{Process.pid}"
    FileUtils.rm_f(socket) if File.exist?(socket)
  end

  describe "when first created" do
    it "maintains the parent pid even when passed to a subprocess" do
      parent_pid = Process.pid
      TestHarness.test_in_subprocess do
        @manager.reset_in_child
        @manager.expected_ppid.should == parent_pid
      end
    end

    it "stores its unix socket at /tmp/critical.sock" do
      @manager.socket_file.should == "/tmp/critical-sock"
    end
  end

  it "creates a unix socket server when starting IPC" do
    @manager.start_ipc
    @manager.ipc_started?.should be_true
    @manager.server.should be_a_kind_of(UNIXServer)
    @manager.server.inspect.should match(%r|#{Regexp.escape("/tmp/critical-sock")}|)
  end

  it "forks a worker process and gives it a care package" do
    parent_pid = Process.pid
    @manager.start_ipc
    pid = @manager.spawn_worker do |care_package|
      begin
        care_package.socket.inspect.should match(%r[#{Regexp.escape("/tmp/critical-sock")}])
        care_package.heartbeat_file.should be_an_instance_of(HeartbeatFile)
        exit!(0)
      rescue Exception => e
        puts "#{e.class.name}: #{e.message}"
        puts e.backtrace.join("\n")
        exit!(42)
      end
    end
    _, status = Process.waitpid2(pid)
    status.should be_success
  end

  it "keeps a copy of the care package for each child" do
    parent_pid = Process.pid
    pid = @manager.spawn_worker { |c| exit! }
    Process.waitpid2(pid)
    @manager.children.should have_key(pid)
    care_package = @manager.children[pid]
    care_package.socket.inspect.should match(%r[#{Regexp.escape("/tmp/critical-sock")}])
    care_package.heartbeat_file.should be_an_instance_of(HeartbeatFile)
  end

  it "kills and reaps all children" do
    begin
      child = @manager.spawn_worker { |c| sleep }
      @manager.killall
      lambda {Process.waitpid2(child, Process::WNOHANG)}.should raise_error(Errno::ECHILD)
      child = nil
    ensure
      Process.kill(:TERM, child) if child
    end
  end

  it "spawns multiple workers at once" do
    begin
      children = @manager.spawn_worker(2) { |c| sleep }
      children.should have(2).workers
      @manager.killall
      children = nil
    ensure
      children.each { |child| Process.kill(:TERM, child) rescue nil} if children
    end
  end

  it "resets all state but doesn't close the heartbeat file belonging to $pid" do
    child_pid = @manager.spawn_worker { |ipc| exit! }
    Process.waitpid2(child_pid)
    child_pid2 = @manager.spawn_worker { |ipc| exit! }
    Process.waitpid2(child_pid2)
    @manager.children.keys.should include(child_pid, child_pid2)
    first_child_hb_file = @manager.children[child_pid].heartbeat_file
    second_child_hb_file = @manager.children[child_pid2].heartbeat_file
    @manager.reset_in_child(child_pid)
    @manager.children.should be_empty
    first_child_hb_file.should_not be_closed
    second_child_hb_file.should be_closed
  end

  it "reaps and respawns crashed workers" do
    crashed_child = @manager.spawn_worker { |ipc| exit! }

    @manager.children.should have_key(crashed_child)
    child_process_spec = @manager.children[crashed_child]

    sleep 0.1
    @manager.manage_workers
    lambda {Process.waitpid2(crashed_child, Process::WNOHANG)}.should raise_error(Errno::ECHILD)
    @manager.children.should_not have_key(crashed_child)
    @manager.children.should have(1).keys
    @manager.children[@manager.children.keys.first].should == child_process_spec
  end

  it "kills, reaps and respawns workers that have timed-out on heartbeating" do
    begin
      stuck_worker = @manager.spawn_worker { |ipc| sleep }

      child_process_spec = @manager.children[stuck_worker]

      too_late_for_stuck_worker = Time.now + @manager.timeout_time + 1
      Time.stub!(:now).and_return(too_late_for_stuck_worker)

      @manager.timed_out?(child_process_spec).should be_true

      @manager.manage_workers
      sleep 0.1
      lambda {Process.waitpid2(stuck_worker, Process::WNOHANG)}.should raise_error(Errno::ECHILD)
      @manager.children.should_not have_key(stuck_worker)
      @manager.children.should have(1).keys
      @manager.children[@manager.children.keys.first].should == child_process_spec
    ensure
      @manager.killall
    end
  end

  it "sends messages to the work queue" do
    @manager.start_ipc

    begin
      child = fork do
        conn = @manager.server.accept
        conn.gets
        conn.puts("ohai")
        conn.close
        exit!(0)
      end

      @manager.dispatch do |sock|
        sock.puts("hello")
        sock.gets.chomp.should == "ohai"
        sock.flush
      end
    ensure
      Process.waitpid2(child) if child
    end
  end

  it "selects on its self_pipe with a given timeout" do
    IO.should_receive(:select).with([an_instance_of(IO)], nil,nil , 10)
    @manager.sleep(10)
  end

  it "sends a QUIT to children when it receives QUIT" do
    pending
  end

  it "sends a TERM to children when it receives INT or TERM" do
    pending
  end

end

describe Subprocess do

  before do
    @child = TestHarness::Worker.new
    @socket_file = Tempfile.new("critical-rspec-socket").path
    @heartbeat_file = HeartbeatFile.new
    FileUtils.rm_f(@socket_file)
    @socket = UNIXServer.new(@socket_file)
    @socket.listen(2)
    @ipc = IPCData.new(@socket, @heartbeat_file, 23)
  end

  after do
    FileUtils.rm_f(@socket_file)
    @heartbeat_file.close
  end

  it "sets the process name to 'critical : worker[NUMBER]'" do
    TestHarness.test_in_subprocess do
      @child.setup_ipc(@ipc)
      $0.should match(%r[#{Regexp.escape('critical : worker[23]')}])
    end
  end

  it "sets up a loop yielding the message from the master" do
    UNIXSocket.open(@socket_file) { |s| s.puts("."); s.flush; }

    TestHarness.test_in_subprocess do
      #Critical.config.log_level = :debug
      @child.setup_ipc(@ipc)
      @child.each_message(@ipc) { |task| task.message.should == ".\n"; exit!(0) }
    end
  end

  it "chmods the heartbeat file at least once through each loop" do
    UNIXSocket.open(@socket_file) { |s| s.puts("."); s.flush; }

    original_ctime = @heartbeat_file.stat.ctime
    sleep(1.1) # ctime resolution is 1s on my system
    TestHarness.test_in_subprocess do
      Critical.config.log_level = :info
      @child.setup_ipc(@ipc)
      @child.each_message(@ipc) { |task| task.message.should == ".\n"; exit!(0) }
    end

    @heartbeat_file.stat.ctime.should_not == original_ctime
    (@heartbeat_file.stat.ctime > original_ctime).should be_true
  end


end
