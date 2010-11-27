require 'critical/protocol'
require 'critical/application/daemon'
require 'critical/application/configuration'
require 'critical/file_loader'
require 'critical/process_manager'
require 'critical/monitor_runner'

module Critical

  # Signals that should handled in the default way (process exit) in the workers
  SIGNALS = [:QUIT, :INT, :TERM, :USR1, :USR2, :HUP ]

  module Application
    class Main
      include Loggable

      ACTION_QUEUE = []
      SELF_PIPE = []

      def run
        configure
        log.info {"Critical is starting up, current PID: #{Process.pid}"}
        load_sources
        validate_config
        config.continuous? ? run_continous : run_single
      end

      def run_single
        scheduler.each do |task|
          runner.run_monitor(task.monitor)
        end
      end

      # a MonitorRunner used in single run mode
      def runner
        @runner ||= MonitorRunner.new(nil)
      end

      def run_continous
        daemonize! if daemonizing?
        init_self_pipe
        setup_signal_handling
        spawn_workers
        run_main_loop
      end
      
      def configure
        Configuration.configure!
      end
      
      def load_sources
        config.source_files.each do |source_file|
          FileLoader.load_metrics_and_monitors_in(source_file)
        end
      end
      
      def daemonize!
        Daemon.daemonize(:pidfile => config.pidfile)
      end
      
      def daemonizing?
        config.daemonize?
      end

      def init_self_pipe
        SELF_PIPE.replace(IO.pipe)
      end

      def setup_signal_handling
        SIGNALS.each do |signal|
          trap(signal) { ACTION_QUEUE.unshift(signal); awaken}
        end
      end
      
      def spawn_workers
        log.info { "starting workers" }
        process_manager.start_ipc
        process_manager.spawn_worker(3) do |ipc|
          MonitorRunner.new(ipc).run
        end
      end

      def run_main_loop
        # ACTION_QUEUE contains the in-order list of Scheduler::Task items to
        # run and any signals received
        loop do
          case next_action = ACTION_QUEUE.shift
          when Scheduler::Task
            run_monitor_task_for(next_action)
          when :INT, :USR1, :USR2, :HUP
            log.info { "Shutting down immediately on #{next_action} signal" }
            process_manager.killall(false)
            exit(1)
          when :QUIT, :TERM
            log.info { "Graceful shutdown on #{next_action} signal"}
            process_manager.killall(true)
            break
          when nil
            sleep_time = scheduler.time_until_next_task
            log.debug { "sleeping #{sleep_time} seconds until next tasks are due" }
            sleep(sleep_time)
            enqueue_monitor_tasks
            process_manager.manage_workers
          else
            log.error { "Unknown action in the action queue #{next_action.inspect}" }
          end
        end
      end

      # Sleep by selecting on a pipe. If a signal is recieved, the pipe will be
      # written to, waking us from the sleep.
      def sleep(time)
        SELF_PIPE[0].read_nonblock(1024) if IO.select([SELF_PIPE[0]], nil, nil, time)
      rescue Errno::EAGAIN
        true
      end

      def awaken
        SELF_PIPE[1].putc("!")
      end

      def enqueue_monitor_tasks
        scheduler.each do |task|
          ACTION_QUEUE.push(task)
        end
      end

      def run_monitor_task_for(task)
        process_manager.dispatch do |socket|
          Protocol::Client.new(socket).publish_task(task.monitor)
        end
      end

      def scheduler
        @scheduler ||= Scheduler.new(monitor_collection.tasks)
      end

      def process_manager
        ProcessManager.instance
      end
      
      private
      
      def monitor_collection
        MonitorCollection.instance
      end
      
      def config
        Critical.config
      end
      
      # Run a sanity check on the config. Must run after loading files to
      # correctly detect empty monitor collection
      def validate_config
        config.validate_configuration!
      end
      
    end
  end
end