module Critical
  class NotImplementedError < ::NotImplementedError
  end
end

require 'critical/loggable'
require 'critical/protocol'
require 'critical/process_manager'
require 'critical/scheduler'
require 'critical/output_handler'
require 'critical/dsl'
require 'critical/monitor'
require 'critical/story_monitor'
require 'critical/monitor_collection'
require 'critical/monitor_runner'
require 'critical/file_loader'
require 'critical/application'