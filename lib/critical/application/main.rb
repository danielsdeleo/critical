module Critical
  module Application
    class Main
      
      def run
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
        config.source_files.each do |metric_source|
          FileLoader.load_in_context(DSL::TopLevel, metric_source)
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
        scheduler = Scheduler::TaskList.new
        MonitorCollection.instance.tasks.each { |t| scheduler.schedule(t) }
        loop do
          scheduler.run_tasks
          scheduler.sleep_until_next_run
        end
      end
      
      private
      
      def config
        Critical.config
      end
      
    end
  end
end