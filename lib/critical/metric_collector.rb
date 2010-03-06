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
          proxify_reporting_result(coerce(uncoerced_value, report_name.values.first))
        end
      else
        define_method(report_name.to_sym) do
          proxify_reporting_result(instance_eval(&method_body))
        end
      end
    end
    
    def self.monitored_attributes
      @monitored_attributes ||= []
    end
    
    def self.monitors(attribute, opts={})
      monitored_attributes << attribute
      attr_accessor attribute.to_sym
      define_default_attribute(attribute) unless default_attr_defined?
    end
    
    attr_reader   :processing_block, :creator_line, :report
    
    def initialize(arg=nil, &block)
      self.default_attribute= arg if arg && self.respond_to?(:default_attribute=)
      @processing_block = block
      @creator_line = caller.first.sub(/:in \`new\'$/, '')
    end
    
    def metric_name
      self.class.metric_name
    end
    
    def to_s
      metric_name.to_s + "[#{default_attribute}]"
    end
    
    def metadata
      unless @metadata
        @metadata = {:metric_name => metric_name}
        self.class.monitored_attributes.each { |attr_name| @metadata[attr_name] = send(attr_name) }
      end
      @metadata
    end
    
    def result
      @result ||= run_collection_command_or_block
    end
    
    def collect(output_handler)
      reset!
      
      @report = output_handler
      output_handler.metric = self
      
      assert_collection_block_or_command_exists!
      report.collected_at = Time.new
      run_processing_block
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
    
    def run_processing_block
      begin
        # 1.8: lambda {}.arity #=> -1 ; 1.9: lambda {}.arity #=> 0
        instance_eval(&processing_block) if processing_block.arity <= 0
        processing_block.call(self)      if processing_block.arity > 0
      rescue Exception => e
        report.processing_failed(e)
      end
    end
    
    def reset!
      @result, @report = nil, nil
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
    
    def run_collection_command_or_block
      assert_collection_block_or_command_exists!
        
      begin
        result = 
          if collection_command?
            `#{command_with_substitutions}`.criticalize 
          else
            instance_eval(&collection_block).criticalize
          end
      rescue Exception => e
        report.collection_failed(e)
      end
      proxify_reporting_result(result)
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
      when :string
        String(value)
      when :integer
        Integer(value)
      when :array
        Array(value)
      else
        raise ArgumentError, "Can't coerce values to type `#{type}'"
      end
    end
    
    def proxify_reporting_result(result_obj)
      result_obj = result_obj.target if result_obj.respond_to?(:target)
      Proxies::MetricReportProxy.new(result_obj, self)
    end
    
    def assert_collection_block_or_command_exists!
      unless collection_command? || collection_block?
        raise "no collection command or block defined for #{self.class.metric_name}"
      end
    end
    
  end
end
