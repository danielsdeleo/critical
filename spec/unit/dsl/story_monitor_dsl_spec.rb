require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module TestHarness
  class StoryMonitorDSLImplementer
    include DSL::MonitorDSL
    include DSL::StoryMonitorDSL

    def metric_collection
      @collection ||= []
    end

    def push(metric)
      metric_collection << metric
    end

  end
end

describe DSL::StoryMonitorDSL do
  before do
    @dsl = TestHarness::StoryMonitorDSLImplementer.new
  end

  it "creates a new story monitor" do
    @dsl.Story("Sign up for my website").should be_an_instance_of(StoryMonitor)
  end

  it "adds new stories to the metric collection" do
    story = @dsl.Story("Buy stuff from my store")
    @dsl.metric_collection.should have(1).stories
    @dsl.metric_collection.first.should equal story
  end
  
  it "namespaces stories" do
    story = nil
    @dsl.Monitor(:integration) do
      story = Story("My stack is working end to end")
    end
    @dsl.metric_collection.should have(1).stories
    story.fqn.should == '/integration/story(My stack is working end to end)'
  end

  it "passes a given block to the story monitor" do
    story = nil
    @dsl.Monitor(:full_stack) do
      story = Story("every piece is working") do |s|
        s.step("do some stuff")
        s.step("do some other stuff")
      end
    end
    story.should have(2).steps
  end

end