module Critical
  class NotImplementedError < ::NotImplementedError
  end
end

require 'critical/core_ext'
require 'critical/loggable'
require 'critical/scheduler'
require 'critical/output_handler'
require 'critical/expectations'
require 'critical/proxies'
require 'critical/dsl'
require 'critical/monitor'
require 'critical/monitor_collection'
require 'critical/monitor_group'
require 'critical/monitor_runner'
require 'critical/file_loader'
require 'critical/application'