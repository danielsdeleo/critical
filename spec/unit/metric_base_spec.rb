require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module TestHarness
  module MetricClassInMetricBaseSpec
  end
end

require 'singleton'
class SubclassIndex
  include Singleton

  def index
    @index ||= 0
    @index += 1
  end

end

describe MetricBase do

  before do
    @index = SubclassIndex.instance.index
    @metric_class = Class.new(Critical::MetricBase)
    TestHarness::MetricClassInMetricBaseSpec.const_set("MetricBaseSubclass_#{@index}", @metric_class)
    @metric_specification = MetricSpecification.new(@metric_class, :arg, [], nil)
  end

  it "keeps a collect string" do
    @metric_class.collects "df -k"
    @metric_class.collection_command.should == "df -k"
  end

  it "resets collection_command on reset!" do
    @metric_class.collects "df -k"
    @metric_class.reset!
    @metric_class.collection_command.should be_nil
  end

  it "keeps a collect block" do
    @metric_class.collects { 'ohai_caller' }
    @metric_class.collection_block.call.should == 'ohai_caller'
  end

  it "resets collection_block on reset!" do
    @metric_class.collects { puts 'foo' }
    @metric_class.reset!
    @metric_class.collection_block.should be_nil
  end

  it "has a name" do
    @metric_class.metric_name = :foobar_metric
    @metric_class.metric_name.should == :foobar_metric
  end

  it "makes the metric name available to instances" do
    @metric_class.collects "df -k"
    @metric_class.metric_name = :barbaz_metric
    @collector_instance = @metric_class.new(@metric_specification)
    @collector_instance.metric_name.should == :barbaz_metric
  end

  describe "defining reporting methods" do
    before do
      @metric_class.metric_name = "reporting_methods_test_#{rand(200)}"
      @metric_class.collects { 'the answer is 42'}
      @metric = @metric_class.new(@metric_specification)
      @output_handler = OutputHandler::Deferred.new(nil)
    end

    it "defines a method for reporting results" do
      @metric_class.reports(:answer) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric.collect(@output_handler,nil)
      @metric.answer.should == '42'
    end

    it "coerces output into a float" do
      @metric_class.reports(:answer => :number) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric.collect(@output_handler, nil)
      @metric.answer.should == 42.0
    end

    it "coerces output into a string" do
      @metric_class.reports(:answer => :string) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric.collect(@output_handler, nil)
      @metric.answer.should == '42'
    end

    it "coerces output into an integer" do
      @metric_class.reports(:answer => :integer) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric.should respond_to(:answer)
      @metric.collect(@output_handler, nil)
      @metric.answer.should equal(42)
    end

    it "coerces output into an array" do
      @metric_class.reports(:answer => :array) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric.collect(@output_handler, nil)
      @metric.answer.should == ['42']
    end

    it "memoizes the result of report methods" do
      @metric_class.reports(:counter) do
        @call_count ||= 0
        @call_count += 1
      end
      @metric.counter.should == 1
      @metric.counter.should == 1
    end
  end

  describe "defining attributes" do
    before do
      @metric_class.collects "df -k"
      @metric_class.metric_name = :df
      @namespace = []
      @metric_specification = MetricSpecification.new(@metric_class, :arg, @namespace, nil)
      @metric_class.monitors(:filesystem)
      @metric = @metric_class.new(@metric_specification)
    end

    it "keeps a list of monitored attributes" do
      @metric_class.monitored_attributes.should == [:filesystem]
      @metric_class.monitors(:cats)
      @metric_class.monitored_attributes.should == [:filesystem, :cats]
    end

    it "makes the first monitored attribute defined an optional argument to initialize" do
      @metric_specification.default_attribute = "/tmp"
      @metric_class.new(@metric_specification).filesystem.should == "/tmp"
    end

    it "converts itself to a hash of metadata" do
      @metric_specification.default_attribute = "/tmp"
      @metric_class.new(@metric_specification).metadata.should == {:metric_name => :df, :filesystem => '/tmp'}
    end

    it "converts itself to a string of the form metric_name(default_attribute)" do
      @metric_specification.default_attribute = "/tmp"
      @metric_class.new(@metric_specification).to_s.should == "df(/tmp)"
    end

    it "converts itself to a 'safe' string with no slash or paren chars" do
      @metric_specification.default_attribute = "/tmp"
      @namespace.concat [:foo, "bar", :baz]
      @metric = @metric_class.new(@metric_specification)
      @metric.safe_str.should == 'foo.bar.baz.df-tmp'
    end

    it "has a namespace" do
      @namespace.concat [:foo, "bar", :baz]
      @metric.namespace.should == [:foo, "bar", :baz]
    end

    it "generates a fully qualified name from its namespace" do
      @metric_specification.namespace = [:foo, "bar", :baz]
      @metric_specification.default_attribute = "/tmp"
      instance = @metric_class.new(@metric_specification)

      instance.fqn.should == "/foo/bar/baz/df(/tmp)"
    end

  end

  describe "collecting and reporting metrics" do
    before do
      @metric_spec = MetricSpecification.new(@metric_class, :url, [], Proc.new {})
      @output_handler = OutputHandler::Deferred.new(nil)
      @graphite_connection = mock("GraphiteHandler (mocked)")
      @trending_handler = Trending::GraphiteHandler.new(@graphite_connection)

      @metric_class.class_eval { attr_accessor :snitch }
      @metric = @metric_class.new(@metric_spec)
    end

    describe "defining reporting methods" do
      before do
        @metric_class.collects { 'the answer is 42'}
      end

      it "defines a method for reporting results" do
        @metric_class.add_reporting_method(:answer) do
          /([\d]+)$/.match(result).captures.first
        end
         @metric.answer.should == '42'
      end

      it "coerces output into a float" do
        @metric_class.add_reporting_method_with_coercion(:answer, :number) do
          /([\d]+)$/.match(result).captures.first
        end
        @metric.answer.should == 42.0
      end

      it "coerces output into a string" do
        @metric_class.add_reporting_method_with_coercion(:answer, :string) do
          /([\d]+)$/.match(result).captures.first
        end
        @metric.answer.should == '42'
      end

      it "coerces output into an integer" do
        @metric_class.add_reporting_method_with_coercion(:answer, :integer) do
          /([\d]+)$/.match(result).captures.first
        end
        @metric.answer.should equal(42)
      end

      it "coerces output into an array" do
        @metric_class.add_reporting_method_with_coercion(:answer, :array) do
          /([\d]+)$/.match(result).captures.first
        end
        @metric.answer.should == ['42']
      end
    end

    describe "collecting metrics" do

      it "has a reference to the output handler it uses" do
        @metric_class.collects {}
        @metric_spec.processing_block = Proc.new {}
        @metric.collect(@output_handler, @trending_handler)
        @metric.output_handler.should == @output_handler
        @metric.report.should == @output_handler
      end

      it "has a reference to the trending handler" do
        @metric_class.collects {}
        @metric_spec.processing_block = Proc.new {}
        @metric.collect(@output_handler, @trending_handler)
        @metric.trending_handler.should == @trending_handler
      end

      it "raises an error if collect is called and no collection block is defined" do
        lambda {@metric.collect}.should raise_error
      end

      it "takes a block to execute expectations and reporting on checks" do
        @metric_spec.processing_block = Proc.new { 'here I come' }
        @metric.processing_block.call.should == 'here I come'
      end

      it "passes itself into the handler block if a block with arity 1 is given" do
        @metric_class.collects { :some_data }
        @metric_spec.processing_block = Proc.new { |m| m.snitch= :yoshitoshi}
        @metric.collect(@output_handler, @trending_handler)
        @metric.snitch.should == :yoshitoshi
      end

      it "instance evals the block against 'self' if a block with arity 0 is given" do
        @metric_class.collects { :metric_result }
        @metric_spec.processing_block = Proc.new { self.snitch = :yoshiesque }
        @metric.collect(@output_handler, @trending_handler)
        @metric.snitch.should == :yoshiesque
      end

      it "rescues errors that occur during result checking or result handling" do
        @metric_class.collects { :some_data }

        @metric_spec.processing_block = Proc.new { raise Exception, "an example exception" }
        lambda {@metric.collect(@output_handler, @trending_handler)}.should_not raise_error
      end

      it "adds errors during processing to the collection report" do
        @metric_class.collects { :some_data }
        @metric_spec.processing_block = Proc.new { raise Exception, "an example exception" }
        @metric.collect(@output_handler, @trending_handler)

        @metric.report.failed_in.should == :processing
        exception = @metric.report.errors.first
        exception[:name].should == "Exception"
        exception[:message].should == "an example exception"
      end

      it "adds errors during collection to the collection report" do
        @metric_class.collects { raise Exception, "your collection is fail"}
        @metric_spec.processing_block = Proc.new  { result }
        @metric.collect(@output_handler, @trending_handler)


        @metric.report.failed_in.should == :collection
        exception = @metric.report.errors.first
        exception[:name].should == "Exception"
        exception[:message].should == "your collection is fail"
      end
    end

    describe "executing the collection command" do

      it "runs the command and returns the result" do
        @metric_class.collects("echo 'a random string'")
        @metric.collect(@output_handler, @trending_handler)
        @metric.result.strip.should == 'a random string'
      end

      it "calls the block and returns the result" do
        @metric_class.collects { "frab-nab-jab" }
        @metric.collect(@output_handler, @trending_handler)
        @metric.result.should == "frab-nab-jab"
      end

      it "memoizes the result" do
        spy = mock("spies on the collection block/lambda")
        spy.should_receive(:get_message).once.and_return("spy_mock_was_poked")
        @metric_class.collects {spy.get_message}

        @metric.collect(@output_handler, @trending_handler)
        @metric.result.should == "spy_mock_was_poked"
        @metric.result.should == "spy_mock_was_poked"
      end

      it "substitutes symbol-esque substrings with method calls" do
        def @metric.string_to_echo
          'echo _this_'
        end
        @metric_class.collects("echo ':string_to_echo'")
        @metric.collect(@output_handler, @trending_handler)
        @metric.result.strip.should == 'echo _this_'
      end
    end

    describe "tracking the value of a metric" do
      before do
        @metric_class.metric_name = :disk_utilization
        @metric_class.monitors(:filesystem)
        @metric_class.collects { :no_op_for_testing }

        @output_handler = OutputHandler::Deferred.new(nil)
      end
      
      context "when a trending handler is provided" do
        it "writes the value to the Graphite connection" do
          @metric_class.reports(:percentage) { 25 }
          @metric_spec.processing_block = Proc.new { track(:percentage) }
          @metric_spec.namespace = %w[system HOSTNAME]
          @metric_spec.default_attribute = "/"

          @graphite_connection.should_receive(:write).with('system.HOSTNAME.disk_utilization.percentage./', 25)
          @metric.collect(@output_handler, @trending_handler)
        end
      end

      context "when no trending handler is provided" do
        it "continues without error" do
          lambda { @metric.collect(@output_handler) }.should_not raise_exception
        end
      end

    end

    describe "reporting the results of collection" do
      before do
        @metric_class = Class.new(Critical::MetricBase)
        @metric_class.metric_name = :df
        @metric = @metric_class.new(@metric_spec)
        @metric_class.monitors(:filesystem)
        @metric_class.collects { :no_op_for_testing }

        @output_handler = OutputHandler::Deferred.new(nil)
      end

      it "sets the timestamp on the collection object" do
        report_during_collection = nil
        now = Time.new
        Time.stub(:new).and_return(now)
        @metric_spec.processing_block = Proc.new { report_during_collection = report }
        @metric.collect(@output_handler, @trending_handler)
        report_during_collection.collected_at.should == now
      end

      describe "classifying the state of the monitored property" do

        it "reports expectation failures as critical" do
          @metric_spec.processing_block = Proc.new { expect {false} }
          @metric.collect(@output_handler, @trending_handler)
          @metric.metric_status.should == :critical
        end

        it "reports expectation failures as warning when given :warning as the argument" do
          @metric_spec.processing_block = Proc.new { expect(:warning) {false} }
          @metric.collect(@output_handler, @trending_handler)
          @metric.metric_status.should == :warning
        end

        it "reports results as critical" do
          @metric_spec.processing_block = Proc.new { critical {true} }
          @metric.collect(@output_handler, @trending_handler)
          @metric.metric_status.should == :critical
        end

        it "reports results as warning" do
          @metric_spec.processing_block = Proc.new { warning {true} }
          @metric.collect(@output_handler, @trending_handler)
          @metric.metric_status.should == :warning
        end

        it "does not de-escalate results to warning after they've been set to critical" do
          @metric_spec.processing_block = Proc.new { critical {true}; warning {true} }
          @metric.collect(@output_handler, @trending_handler)
          @metric.metric_status.should == :critical
        end

        it "sets the status to critical when collection fails" do
          @metric_class.collects { raise Exception, "your collection is fail"}
          @metric_spec.processing_block = Proc.new { result }
          @metric.collect(@output_handler, @trending_handler)
          @metric.metric_status.should == :critical
        end

        it "sets the status to critical when processing fails" do
          @metric_spec.processing_block = Proc.new { raise Exception, "an example exception" }
          @metric.collect(@output_handler, @trending_handler)
          @metric.metric_status.should == :critical
        end

        it "rescues errors in the assertion block and sets the status to warning/critical" do
          @metric_spec.processing_block = Proc.new { warning {nil.no_method_error} }
          @metric.collect(@output_handler, @trending_handler)
          @metric.metric_status.should == :warning

          @metric_spec.processing_block = Proc.new { critical {nil.no_method_error} }
          @metric.collect(@output_handler, @trending_handler)
          @metric.metric_status.should == :critical
        end

        it "supports rspec for making assertions about values" do
          value = nil
          @metric_spec.processing_block = Proc.new { expect {value.should be_nil } }
          @metric.collect(@output_handler, @trending_handler)
          @metric.metric_status.should == :ok

          value = nil
          @metric_spec.processing_block = Proc.new {expect {value.should_not be_nil}}

          @metric.collect(@output_handler, @trending_handler)
          @metric.metric_status.should == :critical
        end
      end

    end
  end
end
