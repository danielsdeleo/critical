require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

# describe OutputHandler::GroupDispatcher do
#   before do
#     @handler_class = Class.new(OutputHandler::GroupDispatcher)
#     @metric_group = MonitorGroup.new(:disk_checks)
#   end
#   
#   it "keeps a list of desired output handlers" do
#     @handler_class.handler(:text) do |opts|
#       opts[:output] = STDOUT
#     end
#     @handler_class.handler(:deferred, :some_option => :a_setting)
#     @handler_class.handlers.should == {OutputHandler::TextGroupHandler     => {:output => STDOUT}, 
#                                       OutputHandler::DeferredGroupHandler => {:some_option => :a_setting}}
#   end
#   
#   it "raises an error when you try to add a handler that doesn't exist" do
#     @handler_class = Class.new(OutputHandler::GroupDispatcher)
#     lambda {@handler_class.handler(:doesnotexist, :opts=>:dontmatterhere)}.should raise_error
#   end
#   
#   it "passes itself into a block for handy configuration" do
#     @handler_class.configure do |klass|
#       klass.should equal(@handler_class)
#     end
#   end
#   
#   describe "with handlers to dispatch to" do
#     before do
#       @handler_class.handler(:deferred, :some_option => :a_setting)
#       @handler_class.handler(:text, :output => StringIO.new)
#       @handler = @handler_class.new(@metric_group)
#     end
#     
#     it "creates and configures the desired output handlers when setup is called" do
#       @handler.setup({})
#       proxied_handlers = @handler.proxied_handlers.sort {|a,b| a.class.name <=> b.class.name}
#       proxied_handlers.first.should be_an_instance_of(OutputHandler::DeferredGroupHandler)
#       proxied_handlers.last.should  be_an_instance_of(OutputHandler::TextGroupHandler)
#     end
#     
#     it "passes its metric group to the proxied handlers when it creates them" do
#       pending
#     end
# 
#     it "proxies calls to :start to each handler" do
#       @handler.proxied_handlers.each { |proxied| proxied.should_receive(:start) }
#       @handler.start
#     end
#     
#     it "proxies calls to :stop to each handler" do
#       @handler.proxied_handlers.each { |proxied| proxied.should_receive(:stop)  }
#       @handler.stop
#     end
#     
#     it "provides a metric dispatcher which contains metric handlers for the groups it proxies for" do
#       metric_dispatcher = @handler.metric_report
#       metric_dispatcher.should be_an_instance_of(OutputHandler::MetricDispatcher)
#       proxied_handlers = metric_dispatcher.proxied_handlers.sort {|a,b| a.class.name <=> b.class.name}
#       proxied_handlers.first.should be_an_instance_of(OutputHandler::DeferredHandler)
#       proxied_handlers.last.should  be_an_instance_of(OutputHandler::TextHandler)
#     end
#     
#   end
# end
# 
describe OutputHandler::Dispatcher do
  describe "defining output handlers to dispatch to" do
    before do
      @handler_class = Class.new(OutputHandler::Dispatcher)
    end
    
    it "is configured with a handler name and options" do
      @handler_class.handler(:text) do |opts|
        opts[:output] = STDOUT
      end
      @handler_class.handler :deferred, :some_option => :a_setting
      @handler_class.handlers.should == {OutputHandler::Text    => {:output => STDOUT}, 
                                        OutputHandler::Deferred => {:some_option => :a_setting}}
    end
    
    it "raises an error when you try to add a handler that doesn't exist" do
      @handler_class = Class.new(OutputHandler::Dispatcher)
      lambda {@handler_class.handler(:doesnotexist, :opts=>:dontmatterhere)}.should raise_error
    end
    
    it "passes itself into a block for handy configuration" do
      @handler_class.configure do |klass|
        klass.should equal(@handler_class)
      end
    end
    
  end
  
  describe "when proxying messages to other output handlers" do
    before do
      @handler_class = Class.new(OutputHandler::Dispatcher)
      @handler_class.handler :deferred, :some_option => :a_setting
      @handler_class.handler :text, :output => STDOUT
      @handler = @handler_class.new
      @proxied_handlers = @handler.proxied_handlers
    end

    def self.it_dispatches_the_message(message)
      self.it "dispatches :#{message} to individual output handlers" do
        # Make sure we're actually testing something before we get to the real tests
        @proxied_handlers.should_not be_nil
        @proxied_handlers.should_not be_empty

        @proxied_handlers.each { |h| h.should_receive(message) }
        @handler.send(message, :foo)
      end
    end

    it_should_behave_like "a metric output handler"

    it_dispatches_the_message(:collection_started)
    it_dispatches_the_message(:collection_succeeded)
    it_dispatches_the_message(:annotate)
    it_dispatches_the_message(:collection_failed)
    it_dispatches_the_message(:processing_failed)
    it_dispatches_the_message(:expectation_failed)
    it_dispatches_the_message(:expectation_succeeded)
    it_dispatches_the_message(:collection_completed)

    it "sets the metric on all proxied handlers when the metric is set" do
      @handler.metric = :a_metric_collector
      @handler.proxied_handlers.each { |h| h.metric.should == :a_metric_collector }
    end
  end
end
