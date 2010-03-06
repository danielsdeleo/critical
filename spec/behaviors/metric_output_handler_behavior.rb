shared_examples_for "a metric output handler" do
  it "has an accessor for the metric it reports on" do
    @handler.metric = :not_really_a_metric_this_time
    @handler.metric.should == :not_really_a_metric_this_time
  end
  
  it "receives :collection_started when collection begins for an individual metric" do
    @handler.should respond_to :collection_started
  end

  it "receives :collection_succeeded when the command/block that collects the metric succeeds" do
    @handler.should respond_to :collection_succeeded
  end

  it "receives :annotate when a condition that might cause failure later occurs" do
    @handler.should respond_to :annotate
  end

  it "receives :collection_failed when the command/block that collects the metric fails" do
    @handler.should respond_to :collection_failed
  end

  it "receives :processing_failed when processing the metric fails" do
    @handler.should respond_to :processing_failed
  end

  it "receives :expectation_failed when an expectation fails" do
    @handler.should respond_to :expectation_failed
  end

  it "receives :expectation_succeeded when an expectation succeeds" do
    @handler.should respond_to :expectation_succeeded
  end

  it "receives :collection_completed when collection/processing/evaluation of an individual metric is finished" do
    @handler.should respond_to :collection_completed
  end
  
  it "normalizes exceptions into a hash" do
    exception = StandardError.new("your code failed dawg")
    bt = caller
    exception.set_backtrace(bt)
    exception_as_hash = @handler.send :normalize_exception, exception 
    exception_as_hash[:name].should == "StandardError"
    exception_as_hash[:message].should == "your code failed dawg"
    exception_as_hash[:stacktrace].should == bt
  end
  
  it "has an attribute accessor for the collection time" do
    time = Time.new
    @handler.collected_at = time
    @handler.collected_at.should == time
  end
end
