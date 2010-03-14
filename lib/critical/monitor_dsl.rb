require 'singleton'

module Critical
  module MonitorGroupDSL
    class CollectorNameToClassMap < Hash
      include Singleton
    end
    
    extend self
    
    def self.add_metric_collector(method_name, collector_class)
      collector_class_for[method_name.to_sym] = collector_class
      
      class_eval <<-METHOD
        def #{method_name.to_s}(arg=nil, &block)
          metric_instance = collector_class_for[:#{method_name}].new(arg, &block)
          add_metric_to_collection(metric_instance)
          metric_instance
        end 
      METHOD
    end
    
    def add_metric_to_collection(metric_instance)
      raise NotImplementedError, "#{self.class.name} should implement #add_metric_to_collection"
    end
    
    private
    
    def collector_class_for
      CollectorNameToClassMap.instance
    end
    
  end
end