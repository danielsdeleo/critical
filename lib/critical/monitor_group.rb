module Critical
  class MonitorGroup
    include Expectations::Matchers
    include DSL::MonitorDSL
    
    attr_reader :name, :metric_collection
    
    def initialize(name, &block)
      @name = name
      @metric_collection = []
      run_initialize_block(&block) if block_given?
    end
    
    def add_metric_to_collection(metric)
      metric_collection << metric
    end
    
    def collect_all
      OutputHandler::GroupDispatcher.new(self) do |o|
        @metric_collection.each { |metric| metric.collect(o.metric_report) }
      end
    end
    
    def to_s
      "monitor_group[#{name.to_s}]"
    end
    
    private
    
    def run_initialize_block(&block)
      block.call(self) if block.arity > 0
      instance_eval(&block) if block.arity <= 0
    end
    
  end
end