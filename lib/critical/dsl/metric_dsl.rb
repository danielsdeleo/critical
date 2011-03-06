module Critical
  module DSL
    module MetricDSL
      extend self
      extend Loggable
      # define a new metric
      def Metric(metric_name, &class_body)
        metric_collector = Class.new(::Critical::MetricBase)
        metric_class_name = Critical::Metrics.const_set(metric_name.to_s.capitalize, metric_collector)
        metric_collector.metric_name = metric_name
        log.debug { "Defining metric '#{metric_name}' as '#{metric_class_name}'"}
        metric_collector.class_eval(&class_body) if block_given?
        MonitorDSL.define_metric(metric_name, metric_collector)
        metric_collector
      end

    end
  end
end
