module Critical
  class NotImplementedError < ::NotImplementedError
  end
end

# External Deps #

# gem install rspec-expectations
require 'rspec/expectations'
require 'rspec/matchers'

require 'critical/heartbeat_file'
require 'critical/loggable'
require 'critical/protocol'
require 'critical/process_manager'
require 'critical/scheduler'
require 'critical/output_handler'
require 'critical/file_loader'
require 'critical/dsl'
require 'critical/trending/graphite'
require 'critical/metric_collection_instance'
require 'critical/monitor'
require 'critical/story_monitor'
require 'critical/monitor_collection'
require 'critical/monitor_runner'
require 'critical/application'