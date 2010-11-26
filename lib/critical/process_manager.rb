require 'tempfile'
require 'socket'
require 'singleton'

module Critical

  # Signals that should handled in the default way (process exit) in the workers
  SIGNALS = [:QUIT, :INT, :TERM, :USR1, :USR2, :HUP ]

  # == Critical::IPCData
  # When creating a new child process, send them off with a care package
  # containing the parent process id, socket they should accept connections
  # on the heartbeat file they should update, and a worker_id number
  class IPCData < Struct.new(:socket, :heartbeat_file, :worker_id)

    def self.from_worker_data(worker_data)
      new(worker_data.socket, worker_data.heartbeat_file, worker_data.worker_id)
    end

  end

  # == Critical::WorkerProcess
  # Used by the master process to keep track of the child processes. Contains
  # the same information as IPCData plus the block that is passed to the fork()
  # call creating the child process. This is all the information needed to
  # respawn a dead/stuck/crashed child process.
  class WorkerProcess < Struct.new(:socket, :heartbeat_file, :worker_id, :block)
    def initialize(ipc_data, block)

      self[:socket]         = ipc_data.socket
      self[:heartbeat_file] = ipc_data.heartbeat_file
      self[:worker_id]      = ipc_data.worker_id

      self[:block] = block
    end
  end

  # == Critical::ProcessManager
  # Manages the creation and supervision of child processes, including the unix
  # domain socket the children use for the work queue.
  #
  # Much of the implementation of this class (and sibling classes/modules)
  # is heavily inspired by Unicorn[http://unicorn.bogomips.org/].
  # Thanks to Eric Wong et al.
  class ProcessManager
    include Loggable
    include Singleton

    SELF_PIPE = []
    CAUGHT_SIGNALS = []

    # After calling start_ipc this contains a UNIXServer that can be shared
    # by the workers
    attr_reader :server

    # A Hash mapping child process ids to a IPCData with data about the
    # child process
    attr_reader :children

    # In a child process, set to Process.ppid immediately after forking.
    # If this doesn't match the current ppid, the master has died.
    attr_reader :expected_ppid

    def initialize
      @children = {}
      reset
    end

    # Reset *all* state. Shouldn't be needed in normal use, use +reset_in_child+
    # inside child processes to shed unnecessary state.
    def reset
      @server = nil
      @children.each { |pid, child| child.heartbeat_file.close}
      @children.clear
    end

    # reset state, but don't close the heartbeat file belonging to +child_pid+
    # used in the child process to shed references to state it doesn't care
    # about
    def reset_in_child(child_pid=Process.pid)
      @expected_ppid = Process.ppid
      @children.delete(child_pid)
      reset
    end

    def dispatch
      UNIXSocket.open(socket_file) { |s| yield s }
    end

    def start_ipc
      File.unlink(socket_file) if File.exist?(socket_file)
      @server = UNIXServer.open(socket_file)

      SELF_PIPE.replace(IO.pipe)

      # TODO: actually do elegant things with some signals.
      SIGNALS.each do |signal|
        trap(signal) do
          log.info { "exiting on signal #{signal}" }
          stop_workers_and_exit
        end
      end
    end

    def ipc_started?
      !!@server
    end

    def socket_file
      "/tmp/critical-sock"
    end

    # Spawn a worker process, calling the supplied block inside the forked process.
    # The caller is responsible for calling reset_in_child after forking.
    def spawn_worker(worker_count=1, &block)
      start_ipc unless ipc_started?
      child_pids = (1..worker_count).map do |i|
        ipc_data = IPCData.new(@server, HeartbeatFile.new, i)
        child_pid = fork do
          block.call(ipc_data)
        end
        @children[child_pid] = WorkerProcess.new(ipc_data, block)
        child_pid
      end
      worker_count == 1 ? child_pids.first : child_pids
    end

    def respawn(worker_data)
      log.info { "respawning dead worker #{worker_data.worker_id}" }
      child_pid = fork do
        worker_data.block.call(IPCData.from_worker_data(worker_data))
      end
      @children[child_pid] = worker_data
      child_pid
    end

    def manage_workers
      dead_pids = []
      @children.each do |child_pid, worker_data|
        # if it can be reaped, it must have crashed
        if result = Process.waitpid2(child_pid, Process::WNOHANG)
          log.error { "worker process #{worker_data.worker_id} pid: #{child_pid} crashed"}
          dead_pids << child_pid 
        elsif  timed_out?(worker_data)
          kill_and_reap(child_pid)
          dead_pids << child_pid
        end
      end
      dead_pids.each do |dead_pid|
        respawn(@children.delete(dead_pid))
      end
    end

    # Sleep by selecting on a pipe. If a signal is recieved, the pipe will be
    # written to, waking us from the sleep.
    # If a signal requesting a clean exit was caught, returns true, otherwise
    # false.
    def sleep(time)
      if IO.select([SELF_PIPE[0]], nil, nil, time)
        #handle signals...
      else
        false
      end
    end

    def stop_workers_and_exit
      killall
      exit(1)
    end

    def kill_and_reap(pid, signal=:KILL)
      killed = Process.kill(signal, pid) rescue nil
      Process.waitpid(pid) if killed
    end

    # Kills and reaps all known child processes. Used in the test harness
    def killall
      @children.each_key { |p| kill_and_reap(p, :TERM) }
    end

    # Has the worker updated the heartbeat within timeout_time seconds of now?
    def timed_out?(worker_data)
      worker_data.heartbeat_file.time_since_heartbeat > timeout_time
    end

    # The maximum amount of time a worker can go without updating its heartbeat
    # before we kill it off. Currently hardcoded to 5 min.
    #--
    # TODO: ideally this would be a function of what monitor the worker is
    # running, so a long integration monitor that takes 10 minutes would have a
    # long timeout, but a simple df would only be a few seconds. At minimum, it
    # should be globally configurable.
    def timeout_time
      300
    end

  end
  

  # == Critical::Subprocess
  # Mixin to be included into worker classes
  module Subprocess

    READ_WAIT_TIME = 5

    include Loggable

    def setup_ipc(ipc)
      # Change our argv0 for happiness in ps
      $0 = "critical : worker[#{ipc.worker_id}]"
      # Clear any traps that may have been inherited
      SIGNALS.each { |signal| Kernel.trap(signal, nil) }
      # Get rid of any state inherited from the process manager
      ProcessManager.instance.reset_in_child
      # Die instantly on INT (^C)
      Kernel.trap(:INT) { exit!(0) }
      # Die gracefully on TERM and QUIT
      [:TERM, :QUIT].each { |signal|  Kernel.trap(signal) { ipc.socket.close }}
    end

    # Enters the main worker loop. Each task that is pulled off the queue is
    # passed to the (required) block as a DequeuedTask
    def each_message(ipc) # :yields: dequeued_task
      raise ArgumentError, "you must pass a block to #{self.class.name}#each_message" unless block_given?
      all_sockets = [ipc.socket]
      ready_sockets = all_sockets
      log.debug do
        socket_names = all_sockets.map { |s| socket_name(s) }
        "starting worker loop, listening on '#{socket_names.join("', '")}'"
      end

      loop do

        ipc.heartbeat_file.alive!
        
        # accept connections from sockets with pending connections
        ready_sockets.each do |socket|
          accept_connections(socket) { |dequeued_task| yield dequeued_task }
          ipc.heartbeat_file.alive!
        end

        unless Process.ppid == expected_ppid
          log.info { "parent process (#{expected_ppid}) has died, exiting." }
          break
        end

        ipc.heartbeat_file.alive!

        begin
          ready_list = IO.select(all_sockets, nil, nil, READ_WAIT_TIME) or redo
          ready_sockets = ready_list[0]
          # interrupted by a signal
        rescue Errno::EINTR
          ready_sockets = all_sockets
          # selecting on a closed socket:
        rescue Errno::EBADF
          break
        end
      end

    end

    def accept_connections(socket)
      reader = socket.accept_nonblock
      reader.fcntl(Fcntl::F_SETFD, reader.fcntl(Fcntl::F_GETFL) | Fcntl::FD_CLOEXEC)
      log.debug { "accepted connection via #{socket_name(reader)}" }
      Protocol::Client.new(reader).accept_task { |t| yield t }
      # EAGAIN means another worker grabbed the connection or there isn't one there
    rescue Errno::EAGAIN
      nil
      # ECONNABORTED should be rare, but outside programs may write to the job
      # queue so we have to be vigilent
    rescue Errno::ECONNABORTED
      log.debug { "Connection #{reader.inspect} aborted" }
      nil
    end

    def socket_name(socket)
      Socket.unpack_sockaddr_un(socket.getsockname)
    end

    def expected_ppid
      ProcessManager.instance.expected_ppid
    end

  end
  
end