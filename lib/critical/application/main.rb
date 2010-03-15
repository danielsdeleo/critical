module Critical
  module Application
    class Main
      
      def run
        configure
        load_metrics
        load_monitors
        # daemonize if daemonizing?
        # start_monitor_runner
        # start_scheduler
      end
      
      def configure
        Configuration.configure!
      end
      
      def load_metrics
        Configuration.metric_source_files.each do |metric_source|
          FileLoader.load_in_context(MonitorCollection.instance, metric_source)
        end
      end
      
    end
  end
end