require 'singleton'
require 'critical/dsl/hostname'

module Critical
  
  class InvalidNamespace < StandardError
  end

  module DSL
    module MonitorDSL
      class MonitorNameToClassMap < Hash
        include Singleton
      end

      include Hostname

      extend self
    
      def self.define_metric(method_name, collector_class)
        monitor_class_for[method_name.to_sym] = collector_class
      
        class_eval(<<-METHOD, __FILE__, __LINE__ + 1)
          def #{method_name.to_s}(arg=nil, &block)
            monitor = monitor_class_for[:#{method_name}].new(arg, &block)
            monitor.namespace = namespace.dup
            push monitor
            monitor
          end 
        METHOD
      end
    
      attr_reader :interval
    
      def Monitor(namespace_name, &block)
        assert_valid_namespace!(namespace_name)
        namespace.push namespace_name
        block.arity <= 0 ? instance_eval(&block) : yield(self)
        namespace.pop
      end
    
      def namespace
        @namespace ||= []
      end
    
      def current_namespace
        "/#{namespace.join('/')}"
      end

      def every(interval_spec, &block)
        @previous_interval, @interval = @interval, interval_from_spec(interval_spec)
        instance_eval(&block)
        @interval = @previous_interval
      end
    
      def collect_every(interval_spec)
        @interval = interval_from_spec(interval_spec)
      end
    
      def push(monitor)
        raise NotImplementedError, "#{self.class.name} should implement #push"
      end
    
      private
    
      def assert_valid_namespace!(namespace_name)
        unless namespace_name.respond_to?(:to_sym) and !namespace_name.kind_of?(Fixnum)
          reason = "Only strings or symbols can be used as namespace names"
          reason << "You gave #{namespace_name.inspect} (an instance of #{namespace_name.class.name})"
          raise InvalidNamespace, reason
        end
      
        if invalid_char = namespace_name.to_s[/[^A-Za-z_0-9\-]/]
          reason = "The namespace #{namespace_name} is invalid because it contains #{invalid_char}. "
          reason << "Valid characters are: A-Z a-z _ 0-9 -"
          raise InvalidNamespace, reason
        end
      end
    
      def interval_from_spec(interval_spec)
        interval_spec.keys.first * unit_to_seconds(interval_spec.values.first)
      end
    
      def unit_to_seconds(unit)
        case unit.to_s
        when 'min', 'minutes', 'minute', 'm'
          60
        when 'h', 'hours', 'hour'
          3600
        when 'sec', 's', 'seconds', 'second'
          1
        else
          raise ArgumentError, "I dont understand units of #{values.first.to_s}"
        end
      end
    
      def monitor_class_for
        MonitorNameToClassMap.instance
      end
    
    end
  end
end
