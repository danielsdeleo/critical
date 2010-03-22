module Critical
  class MonitorRunner
    include Loggable
    
    attr_reader :queue
    def initialize(queue)
      @queue = queue
    end
    
    def run
      while monitor_name = queue.pop
        if monitor = MonitorCollection.instance.find(monitor_name)
          log.debug { "Starting collection for #{monitor.fqn}"}
          monitor.collect(OutputHandler::Dispatcher.new)
          log.debug { "Finished collection for #{monitor.fqn}"}
        else
          log.error "Could not find monitor named #{monitor_name} to run"
        end
      end
    end
    
  end
end