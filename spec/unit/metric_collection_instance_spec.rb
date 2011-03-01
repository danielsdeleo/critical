require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MetricCollectionInstance do
  before do
    @metric_class = Class.new(Critical::MetricBase)
    @output_handler = OutputHandler::Deferred.new(nil)
    @monitor = @metric_class.new
    @graphite_connection = mock("GraphiteHandler (mocked)")
    @trending_handler = Trending::GraphiteHandler.new(@graphite_connection)

    @metric_collector_class = Class.new(MetricCollectionInstance)
    @metric_collector_class.class_eval { attr_accessor :snitch }
    
    @metric_collection_instance = @metric_collector_class.new(@monitor, @output_handler, @trending_handler)
  end

  describe "defining delegators to the monitor object" do

    it "delegates a delegated attribute" do
      @metric_collector_class.monitors_attribute(:url)
      @monitor = mock("mocked up Monitor", :url => 'http://example.org')
      collector = @metric_collector_class.new(@monitor, @output_handler, @trending_handler)
      collector.url.should == 'http://example.org'
    end

  end

  describe "defining reporting methods" do
    before do
      @metric_class = Class.new(Critical::MetricBase)
      @metric_class.collects { 'the answer is 42'}
      @monitor = @metric_class.new
      @metric_collection_instance = @metric_collector_class.new(@monitor, @output_handler, @trending_handler)
    end

    it "defines a method for reporting results" do
      @metric_collector_class.add_reporting_method(:answer) do
        /([\d]+)$/.match(result).captures.first
      end
       @metric_collection_instance.answer.should == '42'
    end

    it "coerces output into a float" do
      @metric_collector_class.add_reporting_method_with_coercion(:answer, :number) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric_collection_instance.answer.should == 42.0
    end

    it "coerces output into a string" do
      @metric_collector_class.add_reporting_method_with_coercion(:answer, :string) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric_collection_instance.answer.should == '42'
    end

    it "coerces output into an integer" do
      @metric_collector_class.add_reporting_method_with_coercion(:answer, :integer) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric_collection_instance.answer.should equal(42)
    end

    it "coerces output into an array" do
      @metric_collector_class.add_reporting_method_with_coercion(:answer, :array) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric_collection_instance.answer.should == ['42']
    end
  end

  describe "collecting metrics" do

    it "has a reference to the monitor it collects the metric for" do
      @metric_collection_instance.monitor.should == @monitor
    end

    it "has a reference to the output handler it uses" do
      @metric_collection_instance.output_handler.should == @output_handler
      @metric_collection_instance.report.should == @output_handler
    end

    it "has a reference to the trending handler" do
      @metric_collection_instance.trending_handler.should == @trending_handler
    end

    it "raises an error if collect is called and no collection block is defined" do
      lambda {@metric_collection_instance.new.collect}.should raise_error
    end

    it "takes a block to execute expectations and reporting on checks" do
      monitor = @metric_class.new { 'here I come' }
      collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
      collector.processing_block.call.should == 'here I come'
    end

    it "passes itself into the handler block if a block with arity 1 is given" do
      @metric_class.collects { :some_data }
      monitor = @metric_class.new { |m| m.snitch= :yoshitoshi}

      collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
      collector.collect
      collector.snitch.should == :yoshitoshi
    end

    it "instance evals the block against 'self' if a block with arity 0 is given" do
      @metric_class.collects { :metric_result }

      monitor = @metric_class.new { self.snitch = :yoshiesque }
      collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
      collector.collect
      collector.snitch.should == :yoshiesque
    end

    it "rescues errors that occur during result checking or result handling" do
      @metric_class.collects { :some_data }

      monitor = @metric_class.new { raise Exception, "an example exception" }
      collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
      lambda {collector.collect}.should_not raise_error
    end

    it "adds errors during processing to the collection report" do
      @metric_class.collects { :some_data }
      monitor = @metric_class.new { raise Exception, "an example exception" }
      collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
      collector.collect

      collector.report.failed_in.should == :processing
      exception = collector.report.errors.first
      exception[:name].should == "Exception"
      exception[:message].should == "an example exception"
    end

    it "adds errors during collection to the collection report" do
      @metric_class.collects { raise Exception, "your collection is fail"}
      monitor = @metric_class.new { result }
      collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
      collector.collect

      collector.report.failed_in.should == :collection
      exception = collector.report.errors.first
      exception[:name].should == "Exception"
      exception[:message].should == "your collection is fail"
    end
  end

  describe "executing the collection command" do

    it "runs the command and returns the result" do
      @metric_class.collects("echo 'a random string'")
      collector = @metric_collector_class.new(@monitor, @output_handler, @trending_handler)
      collector.result.strip.should == 'a random string'
    end

    it "calls the block and returns the result" do
      @metric_class.collects { "frab-nab-jab" }
      collector = @metric_collector_class.new(@monitor, @output_handler, @trending_handler)
      collector.result.should == "frab-nab-jab"
    end

    it "memoizes the result" do
      spy = mock("spies on the collection block/lambda")
      spy.should_receive(:get_message).once.and_return("spy_mock_was_poked")
      @metric_class.collects {spy.get_message}

      collector = @metric_collector_class.new(@monitor, @output_handler, @trending_handler)
      collector.result.should == "spy_mock_was_poked"
      collector.result.should == "spy_mock_was_poked"
    end

    it "substitutes symbol-esque substrings with method calls" do
      def @monitor.string_to_echo
        'echo _this_'
      end
      @metric_class.collects("echo ':string_to_echo'")
      collector = @metric_collector_class.new(@monitor, @output_handler, @trending_handler)
      collector.result.strip.should == 'echo _this_'
    end
  end

  describe "tracking the value of a metric" do
    before do
      @metric_class = Class.new(Critical::MetricBase)
      @metric_class.metric_name = :disk_utilization
      @metric_class.monitors(:filesystem)
      @metric_class.collects { :no_op_for_testing }

      @output_handler = OutputHandler::Deferred.new(nil)
    end

    it "writes the value to the Graphite connection" do
      @metric_class.reports(:percentage) { 25 }
      monitor = @metric_class.new("/") { track(:percentage); raise "wtf" }
      monitor.namespace = %w[system HOSTNAME]
      collector = monitor.collector(@output_handler, @trending_handler)
      
      $VERBOSE = nil

      @graphite_connection.should_receive(:write).with('system.HOSTNAME.disk_utilization.percentage./', 25)
      collector.collect
      #pp collector.report
    end

  end

  describe "reporting the results of collection" do
    before do
      @metric_class = Class.new(Critical::MetricBase)
      @metric_class.metric_name = :df
      @metric_instance = @metric_class.new
      @metric_class.monitors(:filesystem)
      @metric_class.collects { :no_op_for_testing }

      @output_handler = OutputHandler::Deferred.new(nil)
    end

    it "sets the timestamp on the collection object" do
      report_during_collection = nil
      now = Time.new
      Time.stub(:new).and_return(now)
      monitor = @metric_class.new { report_during_collection = report }
      collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
      collector.collect
      report_during_collection.collected_at.should == now
    end

    describe "classifying the state of the monitored property" do

      it "reports expectation failures as critical" do
        monitor = @metric_class.new { expect {false} }
        collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
        collector.collect
        collector.metric_status.should == :critical
      end

      it "reports expectation failures as warning when given :warning as the argument" do
        monitor = @metric_class.new { expect(:warning) {false} }
        collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
        collector.collect
        collector.metric_status.should == :warning
      end

      it "reports results as critical" do
        monitor = @metric_class.new { critical {true} }
        collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
        collector.collect
        collector.metric_status.should == :critical
      end

      it "reports results as warning" do
        monitor = @metric_class.new { warning {true} }
        collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
        collector.collect
        collector.metric_status.should == :warning
      end

      it "does not de-escalate results to warning after they've been set to critical" do
        monitor = @metric_class.new { critical {true}; warning {true} }
        collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
        collector.collect
        collector.metric_status.should == :critical
      end

      it "sets the status to critical when collection fails" do
        @metric_class.collects { raise Exception, "your collection is fail"}
        monitor = @metric_class.new { result }
        collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
        collector.collect
        collector.metric_status.should == :critical
      end

      it "sets the status to critical when processing fails" do
        monitor = @metric_class.new { raise Exception, "an example exception" }
        collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
        collector.collect
        collector.metric_status.should == :critical
      end

      it "rescues errors in the assertion block and sets the status to warning/critical" do
        monitor = @metric_class.new { warning {nil.no_method_error} }
        collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
        collector.collect
        collector.metric_status.should == :warning

        monitor = @metric_class.new { critical {nil.no_method_error} }
        collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
        collector.collect
        collector.metric_status.should == :critical
      end

      it "supports rspec for making assertions about values" do
        value = nil
        monitor = @metric_class.new { expect {value.should be_nil } }
        collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
        collector.collect
        collector.metric_status.should == :ok

        value = nil
        monitor = @metric_class.new {expect {value.should_not be_nil}}

        collector = @metric_collector_class.new(monitor, @output_handler, @trending_handler)
        collector.collect
        collector.metric_status.should == :critical
      end
    end

  end
end