require 'singleton'

module Critical
  class MonitorCollection
    include Loggable
    include Singleton
    include DSL::MonitorDSL
    include Expectations::Matchers
    
    attr_reader :monitors, :tasks
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
      monitor.fqn = "#{current_namespace}/#{monitor.to_s}"
      log.debug { "adding monitor #{monitor.fqn}"}
      nested_group = namespace.inject(@monitors) { |nested, group| nested[group] ||= {} }
      (nested_group[:monitors] ||= []) << monitor
      @tasks << Scheduler::Task.new(monitor.fqn, (interval || 600)) {|output_handler| monitor.collect(output_handler)}
    end
    
    def current_namespace
      "/#{namespace.join('/')}"
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
      namespace_str = namespace_str.sub(/^\//,'')
      components = []
      while namespace_str.sub!(/^([^\/\(\)]+)\//) { |match| components << $1.to_sym; nil }
      end
      components << namespace_str
    end
    
  end
end