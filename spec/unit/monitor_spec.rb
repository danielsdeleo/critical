require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Monitor do
  before do
    @collector_class = Class.new(Critical::Monitor)
  end

  it "keeps a collect string" do
    @collector_class.collects "df -k"
    @collector_class.collection_command.should == "df -k"
  end

  it "resets collection_command on reset!" do
    @collector_class.collects "df -k"
    @collector_class.reset!
    @collector_class.collection_command.should be_nil
  end

  it "keeps a collect block" do
    @collector_class.collects { 'ohai_caller' }
    @collector_class.collection_block.call.should == 'ohai_caller'
  end

  it "resets collection_block on reset!" do
    @collector_class.collects { puts 'foo' }
    @collector_class.reset!
    @collector_class.collection_block.should be_nil
  end

  it "has a name" do
    @collector_class.metric_name = :foobar_metric
    @collector_class.metric_name.should == :foobar_metric
  end

  it "makes the metric name available to instances" do
    @collector_class.metric_name = :barbaz_metric
    @collector_instance = @collector_class.new
    @collector_instance.metric_name.should == :barbaz_metric
  end

  describe "executing the collection command" do
    before do
      @metric_class = Class.new(Critical::Monitor)
      @metric = @metric_class.new
      @report = OutputHandler::Deferred.new(nil)
    end

    it "raises an error when the class has no command or block defined" do
      lambda {@metric.result}.should raise_error
    end

    it "runs the command and returns the result" do
      @metric_class.collects("echo 'a random string'")
      @metric.result.strip.should == 'a random string'
    end

    it "calls the block and returns the result" do
      @metric_class.collects { "frab-nab-jab" }
      @metric.result.should == "frab-nab-jab"
    end

    it "memoizes the result" do
      spy = mock("spies on the collection block/lambda")
      spy.should_receive(:get_message).once.and_return("spy_mock_was_poked")
      @metric_class.collects {spy.get_message}

      @metric.result.should == "spy_mock_was_poked"
      @metric.result.should == "spy_mock_was_poked"
    end

    it "substitutes symbol-esque substrings with method calls" do
      def @metric.string_to_echo
        'echo _this_'
      end
      @metric_class.collects("echo ':string_to_echo'")
      @metric.result.strip.should == 'echo _this_'
    end

    it "passes its report object on to the command output object" do
      @metric_class.collects { "some_system_data" }
      @metric.result.critical_error_report.should equal @metric.report
    end
  end

  describe "defining reporting methods" do
    before do
      @metric_class = Class.new(Critical::Monitor)
      @metric_class.collects { 'the answer is 42'}
    end

    it "defines a method for reporting results" do
      @metric_class.reports(:answer) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric_class.new.answer.should == '42'
    end

    it "coerces output into a float" do
      @metric_class.reports(:answer => :number) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric_class.new.answer.should == 42.0
    end

    it "coerces output into a string" do
      @metric_class.reports(:answer => :string) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric_class.new.answer.should == '42'
    end

    it "coerces output into an integer" do
      @metric_class.reports(:answer => :integer) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric_class.new.answer.should equal(42)
    end

    it "coerces output into an array" do
      @metric_class.reports(:answer => :array) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric_class.new.answer.should == ['42']
    end
  end

  describe "defining attributes" do
    before do
      @metric_class = Class.new(Critical::Monitor)
      @metric_class.metric_name = :df
      @metric_instance = @metric_class.new
      @metric_class.monitors(:filesystem)
    end

    it "keeps a list of monitored attributes" do
      @metric_class.monitored_attributes.should == [:filesystem]
      @metric_class.monitors(:cats)
      @metric_class.monitored_attributes.should == [:filesystem, :cats]
    end

    it "defines attribute accessors for monitored attributes" do
      @metric_instance.filesystem = '/var'
      @metric_instance.filesystem.should == '/var'
    end

    it "makes the first monitored attribute defined an optional argument to initialize" do
      @metric_class.new("/tmp").filesystem.should == "/tmp"
    end

    it "converts itself to a hash of metadata" do
      @metric_class.new("/tmp").metadata.should == {:metric_name => :df, :filesystem => '/tmp'}
    end

    it "converts itself to a string of the form metric_name(default_attribute)" do
      @metric_class.new("/tmp").to_s.should == "df(/tmp)"
    end

  end

  describe "collecting metrics" do
    before do
      @metric_class = Class.new(Critical::Monitor)
      @metric_class.send(:attr_accessor, :snitch)
      @output_handler = OutputHandler::Deferred.new(nil)
    end

    it "accepts a metric output handler for the duration of the collection" do
      @metric_class.collects { :scandal_in_new_york }
      metric = @metric_class.new { 'come on' }
      metric.collect(@output_handler)
      metric.report.should equal @output_handler
    end

    it "calls back to the output handler to give it a reference to itself" do
      @metric_class.collects { :scandal_in_new_york }
      metric = @metric_class.new { 'come on' }
      metric.collect(@output_handler)
      @output_handler.metric.should equal metric
    end

    it "raises an error if collect is called and no collection block is defined" do
      lambda {@metric_class.new.collect}.should raise_error
    end

    it "takes a block to execute expectations and reporting on checks" do
      metric = @metric_class.new { 'here I come' }
      metric.processing_block.call.should == 'here I come'
    end

    it "passes itself into the handler block if a block with arity 1 is given" do
      @metric_class.collects { :some_data }

      metric = @metric_class.new { |m| m.snitch= :yoshitoshi}
      metric.collect(@output_handler)
      metric.snitch.should == :yoshitoshi
    end

    it "instance evals the block against 'self' if a block with arity 0 is given" do
      @metric_class.collects { :metric_result }

      metric = @metric_class.new { self.snitch = :yoshiesque }
      metric.collect(@output_handler)
      metric.snitch.should == :yoshiesque
    end

    it "resets the results before running the result handler" do
      @metric_class.collects { :some_data }
      metric = @metric_class.new { result.should == 'foo' }
      metric.instance_variable_set(:@result, 'FAIL')
      metric.collect(@output_handler)
    end

    it "resets the metric status to :ok on reset" do
      @metric_class.collects { :some_data }
      metric = @metric_class.new {}
      metric.instance_variable_set(:@metric_status, :critical)
      metric.collect(@output_handler)
      metric.metric_status.should == :ok
    end

    it "rescues errors that occur during result checking or result handling" do
      @metric_class.collects { :some_data }

      metric = @metric_class.new { raise Exception, "an example exception" }
      lambda {metric.collect(@output_handler)}.should_not raise_error
    end

    it "adds errors during processing to the collection report" do
      @metric_class.collects { :some_data }
      metric = @metric_class.new { raise Exception, "an example exception" }
      metric.collect(@output_handler)

      metric.report.failed_in.should == :processing
      exception = metric.report.errors.first
      exception[:name].should == "Exception"
      exception[:message].should == "an example exception"
    end

    it "adds errors during collection to the collection report" do
      @metric_class.collects { raise Exception, "your collection is fail"}
      metric = @metric_class.new { result }
      metric.collect(@output_handler)

      metric.report.failed_in.should == :collection
      exception = metric.report.errors.first
      exception[:name].should == "Exception"
      exception[:message].should == "your collection is fail"
    end
  end

  describe "reporting the results of collection" do
    before do
      @metric_class = Class.new(Critical::Monitor)
      @metric_class.metric_name = :df
      @metric_instance = @metric_class.new
      @metric_class.monitors(:filesystem)
      @metric_class.collects { :no_op_for_testing }

      @output_handler = OutputHandler::Deferred.new(nil)
    end

    it "uses a unique report object for each collection run" do
      first_report = @metric_instance.report
      @metric_instance.collect(@output_handler)
      @metric_instance.report.should_not equal(first_report)
    end

    it "sets the timestamp on the collection object" do
      report_during_collection = nil
      now = Time.new
      Time.stub(:new).and_return(now)
      @metric_instance = @metric_class.new { report_during_collection = report }
      @metric_instance.collect(@output_handler)
      report_during_collection.collected_at.should == now
    end

    describe "classifying the state of the monitored property" do
      it "reports results as critical" do
        @metric_instance = @metric_class.new { critical {true} }
        @metric_instance.collect(@output_handler)
        @metric_instance.metric_status.should == :critical
      end

      it "reports results as warning" do
        @metric_instance = @metric_class.new { warning {true} }
        @metric_instance.collect(@output_handler)
        @metric_instance.metric_status.should == :warning
      end

      it "does not de-escalate results to warning after they've been set to critical" do
        @metric_instance = @metric_class.new { critical {true}; warning {true} }
        @metric_instance.collect(@output_handler)
        @metric_instance.metric_status.should == :critical
      end

      it "sets the status to critical when collection fails" do
        @metric_class.collects { raise Exception, "your collection is fail"}
        metric = @metric_class.new { result }
        metric.collect(@output_handler)
        metric.metric_status.should == :critical
      end

      it "sets the status to critical when processing fails" do
        metric = @metric_class.new { raise Exception, "an example exception" }
        metric.collect(@output_handler)
        metric.metric_status.should == :critical
      end
    end

  end

end