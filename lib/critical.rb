module Critical
  class NotImplementedError < StandardError
  end
end

require 'critical/core_ext'
require 'critical/cli_option_parser'
require 'critical/scheduler'
require 'critical/output_handler'
require 'critical/expectations'
require 'critical/proxies'
require 'critical/dsl'
require 'critical/metric_collector'
require 'critical/monitor_collection'
require 'critical/monitor_group'
require 'critical/file_loader'
require 'critical/application'