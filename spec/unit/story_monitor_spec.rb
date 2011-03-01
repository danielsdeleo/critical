require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe StoryMonitor do
  before do
    @story_monitor = StoryMonitor.new("Users can sign up for a blog and post articles")
  end

  it "has a title" do
    @story_monitor.title.should == "Users can sign up for a blog and post articles"
  end
  
  it "has a fully qualified name" do
    @story_monitor.fqn = "story(Users can sign up for a blog and post articles)"
    @story_monitor.fqn.should == "story(Users can sign up for a blog and post articles)"
  end

  it "has no steps when first created" do
    @story_monitor.should have(0).steps
  end

  it "defines a new step by calling #step or #Step" do
    @story_monitor.step("fill out my service's signup form")
    @story_monitor.should have(1).steps
    @story_monitor.steps.first.title.should == "fill out my service's signup form"
  end

  it "defines a new step by calling #given or #Given" do
    @story_monitor.should respond_to(:Given)
    @story_monitor.given("I have submitted the signup form")
    @story_monitor.should have(1).steps
    @story_monitor.steps.first.title.should == "Given I have submitted the signup form"
  end

  it "defines a new step by calling #when or #When" do
    @story_monitor.should respond_to(:When)
    @story_monitor.when("I post an article to my blog")
    @story_monitor.should have(1).steps
    @story_monitor.steps.first.title.should == "When I post an article to my blog"
  end

  it "defines a new step by calling #then or #Then" do
    @story_monitor.should respond_to(:Then)
    @story_monitor.then("I should see my blog post")
    @story_monitor.should have(1).steps
    @story_monitor.steps.first.title.should == "Then I should see my blog post"
  end

  it "converts to a string as story(title)" do
    @story_monitor.to_s.should == "story(Users can sign up for a blog and post articles)"
  end

  it "evaluates a block on initialize" do
    story_monitor = StoryMonitor.new("creating a story monitor with a block") do |s|
      s.given "I am inside the story monitor block"
      s.when  "I add a step"
      s.then  "the step is added to the story"
      s.step  "Note how weirdly meta this is."
    end
    story_monitor.should have(4).steps
  end
  
  it "instance evals a block with arity of 0" do
    story_monitor = StoryMonitor.new("create a story monitor with a 0 arity block") do
      step "When I pass a block of arity 0 to the story monitor"
      step "Then I note that I can't use #when or #then b/c they're ruby keywords"
      step "But otherwise it works just fine"
    end
    story_monitor.should have(3).steps
  end

  it "is scheduled as a whole story" do
    pending "TODO"
  end

  it "provides a data stash where data can be stored between steps" do
    @story_monitor.story_data.should == {}
  end

  it "runs collect on the steps when #collect is called" do
    @story_monitor.step "first!"
    @story_monitor.step "not_first!"
    @story_monitor.steps.each { |s| s.should_receive(:collect).with(:the_output_handler) }
    @story_monitor.collect(:the_output_handler)
  end

end

describe StoryMonitor::Step do
  before do
    @metric = Class.new(Critical::MetricBase)
    @metric.metric_name = :browser
    @metric.monitors(:base_url)
    @monitor = @metric.new
    Critical::DSL::MonitorDSL.define_metric(:browser, @metric)

    @story = StoryMonitor.new("Create a new blog and write an article")
    @step = StoryMonitor::Step.new("When I create a blog post", @story)
  end

  it "has a title" do
    @step.title.should == "When I create a blog post"
  end

  it "belongs to a story" do
    @step.story.should equal @story
  end

  it "has no monitors when created" do
    @step.should have(0).monitors
  end

  it "pushes new monitors into its collection" do
    @step.push @monitor
    @step.should have(1).monitors
    @step.push @monitor
    @step.should have(2).monitors
  end

  it "builds a collection of monitors created via DSL" do
    @step.browser("http://example.com")
    @step.browser("http://example.com/other_app")
    @step.should have(2).monitors
  end

  it "provides access to the story data stash" do
    @story.story_data[:stash_some_data] = "up_in_here"
    @step.story_data[:stash_some_data].should == "up_in_here"
  end

  it "triggers its monitors to collect" do
    @step.browser("http://example.com")
    @step.browser("http://example.com/other_app")
    @step.monitors.each { |m| m.should_receive(:collect).with(:the_output_handler) }
    @step.collect(:the_output_handler)
  end

end
