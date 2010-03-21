require 'singleton'

module Critical
  class MonitorCollection
    include Singleton
    include DSL::MonitorDSL
    
    attr_reader :monitors, :tasks
    def initialize
      reset!
    end
    
    def reset!
      @monitors, @tasks = {}, []
    end
    
    def push(monitor)
      nested_group = namespace.inject(@monitors) { |nested, group| nested[group] ||= {} }
      (nested_group[:monitors] ||= []) << monitor
      @tasks << Scheduler::Task.new(interval || 600) {|output_handler| monitor.collect(output_handler)}
    end
    
  end
end