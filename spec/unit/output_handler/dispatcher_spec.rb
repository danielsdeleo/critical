require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe OutputHandler::GroupDispatcher do
  before do
    @handler_class = Class.new(OutputHandler::GroupDispatcher)
    @metric_group = MonitorGroup.new(:disk_checks)
  end
  
  it "keeps a list of desired output handlers" do
    @handler_class.handler(:text) do |opts|
      opts[:output] = STDOUT
    end
    @handler_class.handler(:deferred, :some_option => :a_setting)
    @handler_class.handlers.should == {OutputHandler::TextGroupHandler     => {:output => STDOUT}, 
                                      OutputHandler::DeferredGroupHandler => {:some_option => :a_setting}}
  end
  
  it "raises an error when you try to add a handler that doesn't exist" do
    @handler_class = Class.new(OutputHandler::GroupDispatcher)
    lambda {@handler_class.handler(:doesnotexist, :opts=>:dontmatterhere)}.should raise_error
  end
  
  it "passes itself into a block for handy configuration" do
    @handler_class.configure do |klass|
      klass.should equal(@handler_class)
    end
  end
  
  describe "with handlers to dispatch to" do
    before do
      @handler_class.handler(:deferred, :some_option => :a_setting)
      @handler_class.handler(:text, :output => StringIO.new)
      @handler = @handler_class.new(@metric_group)
    end
    
    it "creates and configures the desired output handlers when setup is called" do
      @handler.setup({})
      proxied_handlers = @handler.proxied_handlers.sort {|a,b| a.class.name <=> b.class.name}
      proxied_handlers.first.should be_an_instance_of(OutputHandler::DeferredGroupHandler)
      proxied_handlers.last.should  be_an_instance_of(OutputHandler::TextGroupHandler)
    end
    
    it "passes its metric group to the proxied handlers when it creates them" do
      pending
    end

    it "proxies calls to :start to each handler" do
      @handler.proxied_handlers.each { |proxied| proxied.should_receive(:start) }
      @handler.start
    end
    
    it "proxies calls to :stop to each handler" do
      @handler.proxied_handlers.each { |proxied| proxied.should_receive(:stop)  }
      @handler.stop
    end
    
    it "provides a metric dispatcher which contains metric handlers for the groups it proxies for" do
      metric_dispatcher = @handler.metric_report
      metric_dispatcher.should be_an_instance_of(OutputHandler::MetricDispatcher)
      proxied_handlers = metric_dispatcher.proxied_handlers.sort {|a,b| a.class.name <=> b.class.name}
      proxied_handlers.first.should be_an_instance_of(OutputHandler::DeferredHandler)
      proxied_handlers.last.should  be_an_instance_of(OutputHandler::TextHandler)
    end
    
  end
end

describe OutputHandler::MetricDispatcher do
  before do
    @group_handler_class = Class.new(OutputHandler::GroupDispatcher)
    @metric_group = MonitorGroup.new(:disk_checks)
    @group_handler_class.handler(:deferred, :some_option => :a_setting)
    @group_handler_class.handler(:text, :output => StringIO.new)
    @group_handler = @group_handler_class.new(@metric_group)
    @handler = OutputHandler::MetricDispatcher.new(@group_handler)
    @proxied_handlers = @handler.proxied_handlers
  end
  
  def it_dispatches_the_message(message)
    @proxied_handlers.each { |h| h.should_receive(message) }
    @handler.send(message, :foo)
  end
  
  it_should_behave_like "a metric output handler"
  
  it "dispatches messages about metric collection status to each individual handler" do
    it_dispatches_the_message(:collection_started)
    it_dispatches_the_message(:collection_succeeded)
    it_dispatches_the_message(:annotate)
    it_dispatches_the_message(:collection_failed)
    it_dispatches_the_message(:processing_failed)
    it_dispatches_the_message(:expectation_failed)
    it_dispatches_the_message(:expectation_succeeded)
    it_dispatches_the_message(:collection_completed)
  end
  
  it "sets the metric on all proxied handlers when the metric is set" do
    @handler.metric = :a_metric_collector
    @handler.proxied_handlers.each { |h| h.metric.should == :a_metric_collector }
  end
  
end