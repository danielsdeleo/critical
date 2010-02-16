require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MetricCollector do
  before do
    MetricCollector.reset!
  end
  
  it "keeps a collect string" do
    MetricCollector.collects "df -k"
    MetricCollector.collection_command.should == "df -k"
  end
  
  it "resets collection_command on reset!" do
    MetricCollector.collects "df -k"
    MetricCollector.reset!
    MetricCollector.collection_command.should be_nil
  end
  
  it "keeps a collect block" do
    MetricCollector.collects { 'ohai_caller' }
    MetricCollector.collection_block.call.should == 'ohai_caller'
  end
  
  it "resets collection_block on reset!" do
    MetricCollector.collects { puts 'foo' }
    MetricCollector.reset!
    MetricCollector.collection_block.should be_nil
  end
  
  describe "executing the collection command" do
    before do
      @metric_class = Class.new(MetricCollector)
      @metric = @metric_class.new
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
      
      @metric.result
      @metric.result
    end
    
    it "substitutes symbol-esque substrings with method calls" do
      def @metric.string_to_echo
        'echo _this_'
      end
      @metric_class.collects("echo ':string_to_echo'")
      @metric.result.strip.should == 'echo _this_'
    end
  end
  
  describe "defining reporting methods" do
    before do
      @metric_class = Class.new(MetricCollector)
      @metric_class.collects { 'the answer is 42'}
    end
    
    it "defines a method for reporting results" do
      @metric_class.reports(:answer) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric_class.new.answer.should == '42'
    end
    
    it "coerces output into a given type" do
      @metric_class.reports(:answer => :number) do
        /([\d]+)$/.match(result).captures.first
      end
      @metric_class.new.answer.should == 42
    end
  end
  
  describe "defining attributes" do
    before do
      @metric_class = Class.new(MetricCollector)
      @metric_instance = @metric_class.new
    end
    
    it "defines attribute accessors for monitored attributes" do
      @metric_class.monitors(:filesystem)
      @metric_instance.filesystem = '/var'
      @metric_instance.filesystem.should == '/var'
    end
    
    it "makes the first monitored attribute defined an optional argument to initialize" do
      @metric_class.monitors(:filesystem)
      @metric_class.new("/tmp").filesystem.should == "/tmp"
    end
    
  end
  
  describe "collecting metrics" do
    before do
      @metric_class = Class.new(MetricCollector)
      @metric_class.send(:attr_accessor, :snitch)
    end
    
    it "raises an error if collect is called and no collection block is defined" do
      lambda {@metric_class.new.collect}.should raise_error
    end
    
    it "takes a block to execute expectations and reporting on checks" do
      metric = @metric_class.new { 'here I come' }
      metric.handler_block.call.should == 'here I come'
    end
    
    it "passes itself into the handler block if a block with arity 1 is given" do
      @metric_class.collects { :some_data }
      
      metric = @metric_class.new { |m| m.snitch= :yoshitoshi}
      metric.collect
      metric.snitch.should == :yoshitoshi
    end

    it "instance evals the block against 'self' if a block with arity 0 is given" do
      @metric_class.collects { :metric_result }
      
      metric = @metric_class.new { self.snitch = :yoshiesque }
      metric.collect
      metric.snitch.should == :yoshiesque
    end
    
    it "resets the results after running the result handler" do
      @metric_class.collects { :some_data }
      metric = @metric_class.new { result.should == 'foo' }
      metric.collect
      metric.instance_variable_get(:@result).should be_nil #better way?
    end
    
    it "rescues errors that occur during result checking or result handling" do
      @metric_class.collects { :some_data }
      
      metric = @metric_class.new { raise Exception }
      lambda {metric.collect}.should_not raise_error
    end
    
    it "makes a failure report available during collection" do
      pending "first, consider how this failure report obj gets bubbled up"
    end
  end
  
end