module Critical
  module Application
    class Main
      include Loggable
      
      def run
        configure
        log.debug {"Critical is starting up, current PID: #{Process.pid}"}
        set_signal_traps
        load_sources
        daemonize! if daemonizing?
        start_scheduler
        start_monitor_runner
      end
      
      def set_signal_traps
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
        @scheduler = Scheduler::TaskList.new(monitor_collection.tasks)
        Thread.new do
          @scheduler.run
        end
      end
      
      def start_monitor_runner
        MonitorRunner.new(@scheduler.queue).run
      end
      
      
      private
      
      def monitor_collection
        MonitorCollection.instance
      end
      
      def config
        Critical.config
      end
      
    end
  end
end