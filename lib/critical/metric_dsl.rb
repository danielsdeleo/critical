module Critical
  module MetricDSL
    extend self
    # define a new metric collector
    def Metric(metric_name)
      metric_collector = Class.new(MetricCollector)
      metric_collector.metric_name = metric_name
      yield metric_collector if block_given?
      MonitorGroupDSL.add_metric_collector(metric_name, metric_collector)
      metric_collector
    end
    
    # define a monitor group
    def Monitor(monitor_group_name, &block)
      monitor_group = MonitorGroup.new(monitor_group_name, &block)
    end
  end
end