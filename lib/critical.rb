module Critical
  class NotImplementedError < StandardError
  end
  
  
  def log(message)
    puts message
  end
end

require 'critical/failure_report'
require 'critical/monitor_group_dsl'
require 'critical/metric_collector'
require 'critical/command_output'
require 'critical/output_fields'
require 'critical/monitor_group'
require 'critical/dsl'