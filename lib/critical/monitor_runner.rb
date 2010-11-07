require 'critical/loggable'
require 'critical/process_manager'

module Critical
  class MonitorRunner
    include Loggable

    include Subprocess

    attr_reader :ipc

    def initialize(ipc)
      @ipc = ipc
    end

    def run
      setup_ipc(@ipc)

      each_message(@ipc) do |task|
        # async: ack, then execute
        task.ack
        run_monitor(task.url)
      end
    end

    def run_monitor(monitor_name)
      if monitor = MonitorCollection.instance.find(monitor_name)
        collect(monitor)
      else
        log.error "Could not find monitor named #{monitor_name} to run"
      end
    end

    private

    def collection
       MonitorCollection.instance
    end

    def collect(monitor)
      log.debug { "Starting collection for #{monitor.fqn}"}
      monitor.collect(OutputHandler::Dispatcher.new)
      log.info { "Collected #{monitor.fqn}"}
    end

  end
end
