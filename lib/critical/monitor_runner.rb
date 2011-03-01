require 'critical/loggable'
require 'critical/process_manager'

module Critical
  class MonitorRunner
    include Loggable

    include Subprocess

    attr_reader :ipc

    def initialize(ipc)
      @ipc = ipc
      @graphite_handler = Trending::GraphiteHandler.new
    end

    def run
      setup_ipc(@ipc)

      each_message(@ipc) do |task|
        # async: ack, then execute
        task.ack
        run_monitor(task.url)
      end
    end

    def run_monitor(metric_fqn)
      if metric_spec = collection.find(metric_fqn)
        collect(metric_spec)
      else
        log.error "Could not find monitor named #{monitor_name} to run"
      end
    end

    private

    def collection
       MonitorCollection.instance
    end

    def collect(metric_spec)
      log.info { "Collecting #{metric_spec.fqn}"}
      metric_spec.new_metric.collect(OutputHandler::Dispatcher.new, @graphite_handler)
      log.debug { "Collected #{metric_spec.fqn}"}
    end

  end
end
