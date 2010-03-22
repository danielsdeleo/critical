require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module Critical
  module TestHarness
    class OutputHandlerSubclass < OutputHandler::Base
    end
  end
end

describe OutputHandler::Base do  
  before do
    @handler = OutputHandler::Base.new
  end
  
  it_should_behave_like "a metric output handler"
  
  it "keeps a hash of the names of subclasses => class objects" do
    OutputHandler::Base.symbol_to_handler.keys.should include(:output_handler_subclass)
    OutputHandler::Base.symbol_to_handler[:output_handler_subclass].should == Critical::TestHarness::OutputHandlerSubclass
  end
end