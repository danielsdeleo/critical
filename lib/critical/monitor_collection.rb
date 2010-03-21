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
    
    def find(*namespace_elements)
      namespace_elements = split_namespaces(namespace_elements.first) if namespace_elements.size == 1
      namespace_elements.inject(monitors) do |namespace, namespace_elem|
        if namespace.has_key?(namespace_elem)
          namespace[namespace_elem]
        elsif namespace.has_key?(:monitors)
          namespace[:monitors].select { |monitor| monitor.to_s == namespace_elem }.first
        end
      end
    end
    
    def split_namespaces(namespace_str)
      namespace_str = namespace_str.dup
      components = []
      while namespace_str.sub!(/^([^\/\(\)]+)\//) { |match| components << $1.to_sym; nil }
      end
      components << namespace_str
    end
    
  end
end