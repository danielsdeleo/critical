module Critical
  class MonitorGroup
    include MonitorGroupDSL
    
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
      @metric_collection.each { |metric| metric.collect }
    end
    
    private
    
    def run_initialize_block(&block)
      block.call(self) if block.arity > 0
      instance_eval(&block) if block.arity <= 0
    end
    
  end
end