module Critical
  module DSL
    module MetricDSL
      extend self
      # define a new metric collector
      def Metric(metric_name)
        metric_collector = Class.new(MetricCollector)
        metric_collector.metric_name = metric_name
        yield metric_collector if block_given?
        MonitorDSL.define_metric(metric_name, metric_collector)
        metric_collector
      end
    
    end
  end
end
