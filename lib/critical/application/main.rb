module Critical
  module Application
    class Main
      
      def run
        configure
        load_sources
        daemonize! if daemonizing?
        start_monitor_runner
        # start_scheduler
      end
      
      def configure
        Configuration.configure!
      end
      
      def load_sources
        config.source_files.each do |metric_source|
          FileLoader.load_in_context(MonitorCollection.instance, metric_source)
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
        
      end
      
      private
      
      def config
        Critical.config
      end
      
    end
  end
end