require 'forwardable'

module Critical

  # == DynamicMetricCollectionInstance
  # Each type of metric will create its own subclass of MetricCollectionInstance
  # These subclasses usually have methods added at runtime so you can conveniently
  # access the results of a metric collection. (See <tt>Critical::Monitor.reports</tt>)
  #
  # These dynamically generated classes will be named after their metrics and
  # "stored" in the DynamicMetricCollectionInstance namespace.
  module DynamicMetricCollectionInstance
  end

  # == MetricCollectionInstance
  # Instances of MetricCollectionInstance are what actually collect metrics.
  # They are created by Monitor objects when Monitor#collect is called.
  class MetricCollectionInstance
    include RSpec::Matchers

    STATUSES = {:ok => 0, :warning => 1, :critical => 2}

    # Dynamically defines a convenience method for accessing the results
    # of a metric collection
    def self.add_reporting_method(name, &method_body)
      define_method(name.to_sym) do
        instance_eval(&method_body)
      end
    end

    # Like add_reporting_method, dynamically defines a convenience method for
    # accessing the results of a method collection. The result of calling
    # the block will be coerced to the type specified by +desired_class+.
    #
    # See MetricCollectionInstance#coerce
    def self.add_reporting_method_with_coercion(name, desired_class, &method_body)
      define_method(name) do
        uncoerced_value = instance_eval(&method_body)
        coerce(uncoerced_value, desired_class)
      end
    end

    # Adds a delegator to the monitor object. That is, <tt>monitors_attribute(:url)</tt>
    # will define a method +url+ that will call <tt>@monitor.url</tt>
    def self.monitors_attribute(attr_name)
      class_eval(<<-DELEGATED, __FILE__, __LINE__)
        def #{attr_name}
          @monitor.#{attr_name}
        end
      DELEGATED
    end

    attr_reader :monitor
    attr_reader :output_handler
    attr_reader :trending_handler
    attr_reader :metric_status

    alias :report :output_handler

    def initialize(monitor, output_handler, trending_handler)
      @monitor, @output_handler, @trending_handler = monitor, output_handler, trending_handler
      @output_handler.metric = @monitor

      @metric_status = :ok
    end

    def processing_block
      @monitor.processing_block
    end

    def collection_command
      @monitor.collection_command
    end

    def collection_command?
      !!collection_command
    end

    def collection_block
      @monitor.collection_block
    end

    def collection_block?
      !!collection_block
    end

    def result
      @result ||= run_collection_command_or_block
    end

    def collect
      report.collected_at = Time.new
      run_processing_block
    end

    def track(what)
      @trending_handler.write_metric(what, send(what), monitor)
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

    # Sets the state of the metric to :warning if the block evaluates to
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

    def run_collection_command_or_block
      begin
        result =
          if collection_command?
            `#{collection_command}`
          else
            instance_eval(&collection_block)
          end
      rescue Exception => e
        update_status(:critical)
        report.collection_failed(e)
      end
      result
    end

    def coerce(value, type)
      case type
      when :number, :float
        Float(value)
      when :string, :str
        String(value)
      when :integer, :int
        Integer(value)
      when :array, :ary
        Array(value)
      else
        raise ArgumentError, "Can't coerce values to type `#{type}'"
      end
    end

  end
end