require 'singleton'

module Critical
  class MonitorCollection
    include Loggable
    include Singleton
    include DSL::MonitorDSL
    include Expectations::Matchers
    
    attr_reader :tasks
    def initialize
      reset!
    end
    
    def empty?
      @monitors.empty?
    end
    
    def reset!
      @monitors, @tasks = {}, []
    end
    
    def push(monitor)
      log.debug { "adding monitor #{monitor.fqn} to collection"}
      @monitors[monitor.fqn] = monitor
      @tasks << Scheduler::Task.new(monitor.fqn, (interval || 600)) {|output_handler| monitor.collect(output_handler)}
    end
    
    def find(name)
      @monitors[name]
    end
    
  end
end