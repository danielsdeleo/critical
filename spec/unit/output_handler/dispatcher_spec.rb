require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

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
    
    it "aliases handler() to via() and as()" do
      @handler_class.via  :deferred, :some_option => :a_setting
      @handler_class.as   :text, :output => STDOUT
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
