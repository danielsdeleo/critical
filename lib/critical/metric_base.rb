require 'critical/metric_collection_instance'

module Critical
  module Metrics
  end

  # == Critical::UnsupportedPlatform
  # For use by metrics that need to work differently on different platforms.
  # Not used internally
  class UnsupportedPlatform < RuntimeError
  end

  class DefaultAttributeAlreadyDefined < RuntimeError
  end

  class MetricBase

    class << self
      attr_accessor :metric_name
    end

    def self.reset!
      @collection_command, @collection_block, @collection_instance_class = nil, nil, nil
    end

    def self.collection_instance_class
      @collection_instance_class ||= begin
        klass = Class.new(MetricCollectionInstance)
        DynamicMetricCollectionInstance.const_set(metric_name.to_s.capitalize, klass)
        klass
      end
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
          reason = "you must provide only one key and one value when defining reports with a hash. "
          reason << "you gave #{report_name.inspect}"
          raise ArgumentError, reason
        end
        desired_output_class = report_name.values.first
        report_name = report_name.keys.first.to_sym

        collection_instance_class.add_reporting_method_with_coercion( report_name,
                                                                      desired_output_class,
                                                                      &method_body )
      else
        collection_instance_class.add_reporting_method(report_name, &method_body)
      end
    end

    def self.monitored_attributes
      @monitored_attributes ||= []
    end

    def self.monitors(attribute, opts={})
      monitored_attributes << attribute
      if default_attr_defined?
        msg =  "#{@default_attr} was previously defined as the default attribute for #{metric_name}.\n"
        msg << "You can only monitor one attribute per metric. Use a Hash if you need more."
        raise DefaultAttributeAlreadyDefined, msg
      end
      define_default_attribute(attribute)
    end

    private

    def self.define_default_attribute(attr_name)
      #alias_method(:default_attribute=, "#{attr_name.to_s}=".to_sym)
      alias_method(attr_name.to_sym,:default_attribute)
      default_attr_defined(attr_name)
    end

    def self.default_attr_defined(attr_name)
      @default_attr = attr_name
    end

    def self.default_attr_defined?
      @default_attr_defined || false
    end

    public

    attr_reader :metric_specification
    attr_reader :report
    attr_reader :metric_status

    def initialize(metric_specification)
      @metric_specification = metric_specification
    end

    def default_attribute
      metric_specification.default_attribute
    end

    def processing_block
      metric_specification.processing_block
    end

    def namespace
      metric_specification.namespace
    end

    def default_attribute
      metric_specification.default_attribute
    end

    def default_attribute?
      !!default_attribute
    end

    def fqn
      metric_specification.fqn
    end

    def metric_name
      self.class.metric_name
    end

    def to_s
      if default_attribute?
        metric_name.to_s + "(#{default_attribute})"
      else
        metric_name.to_s
      end
    end

    def metadata
      unless @metadata
        @metadata = {:metric_name => metric_name}
        self.class.monitored_attributes.each { |attr_name| @metadata[attr_name] = send(attr_name) }
      end
      @metadata
    end

    def collect(output_handler, trending_handler)
      assert_collection_block_or_command_exists!
      collector(output_handler, trending_handler).collect
    end

    def collector(output_handler, trending_handler)
      self.class.collection_instance_class.new(self, output_handler, trending_handler)
    end

    def collection_command
      self.class.collection_command && command_with_substitutions
    end

    def command_with_substitutions
      @command_with_substitutions ||= begin
        self.class.collection_command.gsub(/:([a-z][a-z0-9_]+)/) do |method_name|
          method_name.sub!(/^:/,'')
          send(method_name.to_sym)
        end
      end
    end

    def collection_block
      self.class.collection_block
    end

    def assert_collection_block_or_command_exists!
      unless collection_command || collection_block
        raise "no collection command or block defined for #{self.class.metric_name}"
      end
    end

  end
end
