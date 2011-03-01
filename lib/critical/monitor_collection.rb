require 'singleton'

module Critical
  class MonitorCollection
    include Loggable
    include Enumerable
    include Singleton
    include DSL::MonitorDSL
    
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
    
    def push(monitor_specification)
      log.debug { "adding monitor #{monitor_specification.fqn} to collection"}
      @monitors[monitor_specification.fqn] = monitor_specification
      @tasks << Scheduler::Task.new(monitor_specification.fqn, (interval || 600))
      self
    end
    alias :<< :push
    
    def find(name)
      @monitors[name]
    end
    
    def each
      @monitors.values.each { |mon| yield mon }
    end
    
  end
end