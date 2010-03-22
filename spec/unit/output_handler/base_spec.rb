require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe OutputHandler::Base do  
  before do
    @handler = OutputHandler::Base.new
  end
  
  it_should_behave_like "a metric output handler"
  
  it "keeps a hash of the names of subclasses => class objects" do
    
  end
end