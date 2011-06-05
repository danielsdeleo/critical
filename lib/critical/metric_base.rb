require 'critical/data_stash'

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

  # == Critical::MetricBase
  # The base class for all metrics. In the DSL, new subclasses will
  # usually be created by calling +MetricDSL#Metric+ (included at the
  # top level, so you can just call +Metric+).
  # === Defining a metric via the DSL
  # To define a metric via the DSL, call +Metric+ with the name of the
  # metric as the argument, passing a block:
  #
  #   Metric(:disk_utilization) do
  #   end
  #
  # === Arugments
  # Metrics can have an argument, such as a URL to hit, the name of a
  # disk partition to monitor, etc. To define this argument, call
  # +monitors+ in the block passed to +Metric+:
  #
  #   Metric(:nginx_stats) do
  #     monitors :nginx_status_url
  #   end
  #
  # === Collecting Data
  # Data can be collected either by executing ruby code or running an
  # external shell command. In both cases, the collection process is
  # defined by calling +collects+. To collect data from a shell command,
  # give a string argument to +collects+:
  #
  #   Metric(:network_connections) do
  #     collects "netstat -n -f inet"
  #   end
  #
  # To collect data by running ruby code, pass a code block to
  # +collects+:
  #
  #   Metric(:nginx_stats) do
  #     collects do
  #       RestClient.get("http://127.0.0.1/nginx_status")
  #     end
  #   end
  #
  # === Processing Data
  # In the typical case, collection code should only aquire the raw
  # data for the metric. Data processing is handled by separate
  # reporting methods. To add a reporting method, call +reports+ with
  # the name of the report and a code block. Within the code block, use
  # +result+ to get the result of the data collection:
  #
  #   Metric(:network_connections) do
  #     collects "netstat -n -f inet"
  #
  #     reports(:count) do
  #       result.split("\n").size
  #     end
  #   end
  #
  # ==== Type Coercion
  # To ensure that the result of a report is of a given class of ruby
  # object, you can pass a Hash of the form <tt>:name => :type</tt> to
  # +reports+. Type coercion uses ruby's capitalized coercion methods
  # (e.g, Array, Integer, String, Float) which are more forgiving than
  # the +Object#to_type+ methods.
  #
  #   Metric(:load_average) do
  #     collects "uptime"
  #
  #     reports(:one_minute_avg => :float) do
  #       result.match(/load averages: ([\d.]+)/)[1]
  #     end
  #   end
  #
  # === Reporting Rates from Counter Data
  # Frequently, data will be reported via counters when you are
  # interested in a rate or average over a certain period. Critical's
  # design makes it impossible to store the previous results in memory,
  # so a filesystem-based key-value store is provided to persist data
  # between collection occurences. To get a DataStash object, call
  # +stash+. Use +save+ and +load+ to store and fetch data:
  #
  #   Metric(:nginx_stats) do
  #     # collection code...
  #
  #     reports(:request_counter) do
  #       request_count = extract_request_count # defined elsewhere...
  #       stash.save( :timestamp => Time.now.to_i,
  #                   :count => request_count )
  #     end
  #
  #     reports(:prior_request_counter) do
  #       stash.load
  #       # returns the data stored last time, e.g.,
  #       # => {:timestamp => 1299447493, :count => 1234}
  #     end
  #   end
  #
  # See DataStashDSL for more documentation.
  #
  class MetricBase
    include RSpec::Matchers
    include DataStashDSL

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

    # Defines a method on the metric class. Used to process the raw data of a
    # metric collection by extracting data, converting units, etc.
    #
    # === Example:
    #
    #   # disk utilization metric, uses df(1)
    #   collects "df -k :filesystem"
    #   # A lovely regex to extract the data from df
    #   df_k_format = /^([\S]+)[\s]+([\d]+)[\s]+([\d]+)[\s]+([\d]+)[\s]+([\d]+)%[\s]+([\S]+)$/
    #   # `result` will contain the output of df. Take the last line of output,
    #   # then run it through the regex and keep the 4th capture.
    #   reports(:percentage => :integer) do
    #     result.last_line.fields(df_k_format).field(4)
    #   end
    def self.reports(report_name, &method_body)
      if report_name.kind_of?(Hash)
        unless report_name.keys.size == 1
          reason = "you must provide only one key and one value when defining reports with a hash. "
          reason << "you gave #{report_name.inspect}"
          raise ArgumentError, reason
        end
        desired_output_class = report_name.values.first
        report_name = report_name.keys.first.to_sym

        add_reporting_method_with_coercion( report_name, desired_output_class, &method_body )
      else
        add_reporting_method(report_name, &method_body)
      end
    end

    def self.monitored_attributes
      @monitored_attributes ||= []
    end

    def self.monitors(attribute, opts={})
      if default_attr_defined?
        msg =  "#{@default_attr} was previously defined as the default attribute for #{metric_name}.\n"
        msg << "You can only monitor one attribute per metric. Use a Hash if you need more."
        raise DefaultAttributeAlreadyDefined, msg
      end
      monitored_attributes << attribute
      define_default_attribute(attribute)
    end


    # Dynamically defines a convenience method for accessing the results
    # of a metric collection. See +reports+
    def self.add_reporting_method(name, &method_body)
      define_method(name.to_sym) do
        @memoized_results[name] ||= instance_eval(&method_body)
      end
    end

    # Like add_reporting_method, dynamically defines a convenience method for
    # accessing the results of a method collection. The result of calling
    # the block will be coerced to the type specified by +desired_class+.
    #
    # See +reports+ and <tt>#coerce</tt>
    def self.add_reporting_method_with_coercion(name, desired_class, &method_body)
      define_method(name) do
        @memoized_results[name] ||= begin
          uncoerced_value = instance_eval(&method_body)
          coerce(uncoerced_value, desired_class)
        end
      end
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

    attr_reader :output_handler
    alias :report :output_handler

    attr_reader :trending_handler

    attr_reader :metric_status

    attr_reader :metric_specification

    attr_reader :metric_status

    def initialize(metric_specification)
      @metric_specification = metric_specification
      @metric_status = :ok
      @memoized_results = {}
    end

    def namespace
      metric_specification.namespace
    end

    def default_attribute
      metric_specification.default_attribute
    end

    def collection_block
      self.class.collection_block
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

    def collection_command?
      !!collection_command
    end

    def collection_block?
      !!collection_block
    end

    def processing_block
      metric_specification.processing_block
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

    # Returns the fully qualified name of the metric, but with all
    # non-shell safe characters removed. The namespace path is joined
    # with dots. For example, a +df+ metric, with a default attribute
    # "/var", in namespace system/hostname/disk_usage, would have
    # this +safe_str+:
    #   system.hostname.disk_usage.df-var
    def safe_str
      name_component = metric_name.to_s
      name_component << "-#{default_attribute.gsub(%r{[^\w]}, '')}" if default_attribute?
      (namespace << name_component).join('.')
    end

    def metadata
      unless @metadata
        @metadata = {:metric_name => metric_name}
        self.class.monitored_attributes.each { |attr_name| @metadata[attr_name] = send(attr_name) }
      end
      @metadata
    end

    # Initiates collection and processing of the metric, with reports
    # and trending data (if any) being sent to +reporting_handler+ and
    # +trending_handler+ respectively. Not usually called by user code.
    def collect(reporting_handler, trending_handler)
      @output_handler, @trending_handler = reporting_handler, trending_handler

      assert_collection_block_or_command_exists!
      @output_handler.collected_at = Time.new
      @output_handler.metric = self
      run_processing_block
    end

    # Returns the result of running the collection command or code
    # block (generally defined by the +collects+ method in the class
    # body). The return value is memoized for each data collection run,
    # so you can call this multiple times and it will be
    # calculated/collected only once.
    def result
      @result ||= run_collection_command_or_block
    end

    # Sends the result of calling the method +what+ to the trending
    # handler (graphite/carbon). For example, if your metric has a
    # method +requests_per_second+ that you want to graph, you write:
    #   track(:requests_per_second)
    def track(what)
      trending_handler.write_metric(what, send(what), self)
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

    def assert_collection_block_or_command_exists!
      unless collection_command || collection_block
        raise "no collection command or block defined for #{self.class.metric_name}"
      end
    end

  end
end
