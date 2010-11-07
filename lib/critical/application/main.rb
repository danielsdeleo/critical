require 'critical/protocol'
require 'critical/application/daemon'
require 'critical/application/configuration'
require 'critical/file_loader'
require 'critical/process_manager'
require 'critical/monitor_runner'

module Critical
  module Application
    class Main
      include Loggable
      
      attr_reader :scheduler_thread
      
      def run
        configure
        log.debug {"Critical is starting up, current PID: #{Process.pid}"}
        load_sources
        validate_config
        daemonize! if daemonizing?
        spawn_workers
        start_scheduler_loop
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
      
      def spawn_workers
        log.info { "starting workers" }
        process_manager.start_ipc
        process_manager.spawn_worker(3) do |ipc|
          MonitorRunner.new(ipc).run
        end
      end

      def start_scheduler_loop
        loop do
          scheduler.each do |monitor|
            process_manager.dispatch do |socket|
              Protocol::Client.new(socket).publish_task(monitor)
            end
          end
          break if process_manager.sleep(scheduler.time_until_next_task)
          # TODO: not implemented :(
          #process_manager.manage_workers
        end
      end
      
      def scheduler
        @scheduler ||= Scheduler::TaskList.new(monitor_collection.tasks)
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