module Critical
  module Metrics
  end

  class Monitor
    STATUSES = {:ok => 0, :warning => 1, :critical => 2}

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
          reason = "you must provide only one key and one value when defining reports with a hash. "
          reason << "you gave #{report_name.inspect}"
          raise ArgumentError, reason
        end
        desired_output_class = report_name.values.first
        report_name = report_name.keys.first.to_sym

        define_method(report_name) do
          uncoerced_value = instance_eval(&method_body)
          coerce(uncoerced_value, desired_output_class)
        end
      else
        define_method(report_name.to_sym) do
          instance_eval(&method_body)
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

    def self.enable_rspec
      include Spec::Matchers
    end

    attr_accessor :fqn
    attr_reader   :processing_block, :report, :metric_status

    def initialize(arg=nil, &block)
      self.default_attribute= arg if arg && self.respond_to?(:default_attribute=)
      @processing_block = block
    end

    def metric_name
      self.class.metric_name
    end

    def to_s
      if respond_to?(:default_attribute)
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

    # Sets the state of the metric to +status_on_failure+ (defaults to :critical)
    # if the block evaluates to false or raises an error. Can be used with rspec
    # matchers if rspec support is enabled. (see Monitor.enable_rspec)
    #
    #   expect { 5 >= 0 }             # doesn't update status
    #   expect { 42 < 5 }             # updates status to critical
    #   expect(:warning) { 23 < 5 }   # updates status to warning
    #   expect { nil.should be_nil }  # rspec support
    #
    def expect(status_on_failure=nil, &block)
      status_on_failure ||= :critical
      begin
        update_status(status_on_failure) unless instance_eval(&block)
      rescue Exception => e
        update_status(status_on_failure)
      end
    end

    # Sets the state of the metric to :critical if the block evaluates to
    # +true+ or raises an error.
    def critical(&block)
      begin
        update_status(:critical) if instance_eval(&block)
      rescue Exception
        update_status(:critical)
      end
    end

    # Sets the state of the metrci to :warning if the block evaluates to
    # +true+ or raises an error.
    def warning(&block)
      begin
        update_status(:warning) if instance_eval(&block)
      rescue Exception
        update_status(:warning)
      end
    end

    # Updates the status of the metric to +status+. The status will only be
    # escalated to a higher level than the current level--it won't go down.
    #
    #   update_status(:warning)   # status is :warning
    #   update_status(:critical)  # status is :critical
    #   update_status(:ok)        # status is still :critical
    #
    def update_status(status)
      @metric_status = status if STATUSES[status] > STATUSES[@metric_status]
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
        update_status(:critical)
        report.processing_failed(e)
      end
    end

    def reset!
      @result, @report = nil, nil
      @metric_status = :ok
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
            `#{command_with_substitutions}`
          else
            instance_eval(&collection_block)
          end
      rescue Exception => e
        update_status(:critical)
        report.collection_failed(e)
      end
      result
    end

    def command_with_substitutions
      collection_command.gsub(/:([a-z][a-z0-9_]+)/) do |method_name|
        method_name.sub!(/^:/,'')
        send(method_name.to_sym)
      end
    end

    def coerce(value, type)
      case type
      when :number, :float
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

    def assert_collection_block_or_command_exists!
      unless collection_command? || collection_block?
        raise "no collection command or block defined for #{self.class.metric_name}"
      end
    end

  end
end
