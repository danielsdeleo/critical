module Critical
  module Application
    class Main
      include Loggable
      
      def run
        log.info {"Starting up"}
        configure
        load_sources
        daemonize! if daemonizing?
        start_monitor_runner
        start_scheduler
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
      
      def start_monitor_runner
        
      end
      
      def start_scheduler
        @scheduler = Scheduler::TaskList.new(monitor_collection.tasks)
        @scheduler.run
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