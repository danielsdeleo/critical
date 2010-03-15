module Critical
  class NotImplementedError < StandardError
  end
end

require 'critical/core_ext'
require 'critical/scheduler'
require 'critical/output_handler'
require 'critical/expectations'
require 'critical/proxies'
require 'critical/monitor_dsl'
require 'critical/metric_collector'
require 'critical/monitor_group'
require 'critical/metric_dsl'
