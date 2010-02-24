module Critical
  class CollectionReport
    
    attr_accessor :collected_at
    attr_reader   :failed_in, :errors, :data
    
    def initialize(collector)
      @collector = collector
      @failure, @errors, @data = false, [], {}
    end
    
    def to_hsh
      as_hash = {}
      as_hash[:metric]              = @collector.metadata
      as_hash[:metric_source_line]  = @collector.creator_line if failed?
      as_hash[:errors]              = failed? ? @errors : []
      as_hash[:failed]              = @failure
      as_hash[:collected_at]        = self.collected_at
      as_hash
    end
    
    def failed?
      @failure
    end
    
    def collection_failed!(*args)
      @failure, @failed_in = true, :collection
      annotate(*args)
    end
    
    def processing_failed!(*args)
      @failure, @failed_in = true, :processing
      annotate(*args)
    end
    
    def expectation_failed!(*args)
      @failure, @failed_in = true, :expectation
      annotate(*args)
    end
    
    def annotate(error, message=nil, trace=nil)
      if error.kind_of?(Exception)
        name, message, trace = error.class.name, error.message, error.backtrace
      end
      name ||= error
      errors << {:name => name, :message => message, :stacktrace => trace || caller}
    end
    
    def collected(data_tag, value)
      data[data_tag] = value
    end
    
  end
end