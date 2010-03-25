module Critical
  module Application
    class Main
      include Loggable
      
      attr_reader :scheduler_thread
      
      def run
        configure
        log.debug {"Critical is starting up, current PID: #{Process.pid}"}
        trap_signals
        load_sources
        validate_config
        daemonize! if daemonizing?
        start_monitor_runner
        start_scheduler
      end
      
      def trap_signals
        Kernel.trap("TERM") do
          raise 'TODO: sensible signal handling'
        end
        Kernel.trap("INT") do
          raise 'TODO: sensible signal handling'
        end
        Kernel.trap("HUP") do 
          raise 'TODO: sensible signal handling'
        end
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
      
      def start_scheduler
        scheduler.run
      end
      
      def start_monitor_runner
        Thread.new do
          MonitorRunner.new(scheduler.queue).run
        end
      end
      
      def scheduler
        @scheduler ||= Scheduler::TaskList.new(monitor_collection.tasks)
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