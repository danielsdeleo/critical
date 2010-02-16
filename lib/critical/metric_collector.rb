module Critical
  class MetricCollector
    
    class << self
      attr_accessor :metric_name
    end
    
    def self.reset!
      @collection_command, @collection_block = nil, nil
    end
    
    def self.collects(command=nil, &block)
      @collection_command, @collection_block = command, nil
      @collection_command, @collection_block = nil, block if block_given?
    end
    
    def self.collection_command
      @collection_command
    end
    
    def self.collection_block
      @collection_block
    end
    
    def self.reports(report_name, &method_body)
      if report_name.kind_of?(Hash)
        unless report_name.keys.size == 1
          raise ArgumentError, "you can't define reports using a hash with more than 1 key"
        end
        
        define_method(report_name.keys.first.to_sym) do
          uncoerced_value = instance_eval(&method_body)
          coerce(uncoerced_value, report_name.values.first)
        end
      else
        define_method(report_name.to_sym, &method_body)
      end
    end
    
    def self.monitors(attribute, opts={})
      attr_accessor attribute.to_sym
      define_default_attribute(attribute) unless default_attr_defined?
    end
    
    attr_reader :handler_block
    
    def initialize(arg=nil, &block)
      self.default_attribute= arg if arg && self.respond_to?(:default_attribute=)
      @handler_block = block
    end
    
    def result
      @result ||= run_command_or_block
    end
    
    def collect
      assert_collection_block_or_command_exists!
      run_handler_block
      reset!
    end
    
    private
    
    def self.define_default_attribute(attr_name)
      alias_method(:default_attribute=, "#{attr_name.to_s}=".to_sym)
      alias_method(:default_attribute,  attr_name.to_sym)
      default_attr_defined
    end
    
    def self.default_attr_defined
      @default_attr_defined = true
    end
    
    def self.default_attr_defined?
      @default_attr_defined || false
    end
    
    def run_handler_block
      begin
        # 1.8: lambda {}.arity #=> -1 ; 1.9: lambda {}.arity #=> 0
        instance_eval(&handler_block) if handler_block.arity <= 0
        handler_block.call(self)      if handler_block.arity > 0
      rescue Exception => e
        # TODO: maybe let some exceptions through, for example Errno::EINTR (SIGINT)
        
        # TODO: replace the below with FailureReport stuff
        #puts("Uncaught Exception #{e.class.name} when running metric handler")
        #puts(e.message)
        #puts(e.backtrace.map {|line| "  " + line})
      end
    end
    
    def reset!
      @result = nil
    end
    
    def collection_command
      self.class.collection_command
    end
    
    def collection_command?
      !!collection_command
    end
    
    def collection_block
      self.class.collection_block
    end
    
    def collection_block?
      !!collection_block
    end
    
    def run_command_or_block
      assert_collection_block_or_command_exists!
      
      return CommandOutput.new(`#{command_with_substitutions}`) if collection_command?
      
      if collection_block
        result = instance_eval(&collection_block)
        return result.kind_of?(String) ? CommandOutput.new(result) : result
      end
    end
    
    def command_with_substitutions
      collection_command.gsub(/:([a-z][a-z0-9_]+)/) do |method_name|
        method_name.sub!(/^:/,'')
        send(method_name.to_sym)
      end
    end
    
    def coerce(value, type)
      case type
      when :number
        Float(value)
      else
        raise ArgumentError, "Can't coerce values to type `#{type}'"
      end
    end
    
    def assert_collection_block_or_command_exists!
      unless collection_command? || collection_block?
        raise "no collection command or block defined for #{self.class.metric_name}"
      end
    end
    
  end
end
