require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module TestHarness
  module MetricClassInMetricBaseSpec
  end
end

describe MetricBase do

  before(:all) do
    @index = 0
  end

  before do
    @index += 1
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
      @metric_class.collection_instance_class.new(@metric,@output_handler,nil).should respond_to(:answer)
      @metric.collector(@output_handler, nil).answer.should == '42'
    end

    it "coerces output into a float" do
      @metric_class.reports(:answer => :number) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric.collector(@output_handler, nil).should respond_to(:answer)
      @metric.collector(@output_handler, nil).answer.should == 42.0
    end

    it "coerces output into a string" do
      @metric_class.reports(:answer => :string) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric.collector(@output_handler, nil).should respond_to(:answer)
      @metric.collector(@output_handler, nil).answer.should == '42'
    end

    it "coerces output into an integer" do
      @metric_class.reports(:answer => :integer) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric.collector(@output_handler, nil).should respond_to(:answer)
      @metric.collector(@output_handler, nil).answer.should equal(42)
    end

    it "coerces output into an array" do
      @metric_class.reports(:answer => :array) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric.collector(@output_handler, nil).should respond_to(:answer)
      @metric.collector(@output_handler, nil).answer.should == ['42']
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


  describe "creating a collector to collect the metrics" do

    it "raises an error when the class has no command or block defined" do
      lambda {@metric_class.new(@metric_specification).collect}.should raise_error
    end

  end

end