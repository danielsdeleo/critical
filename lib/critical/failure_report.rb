module Critical
  class FailureReport
    
    attr_reader :failed_in, :annotations
    
    def initialize
      @failure, @annotations = false, []
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
      @annotations << {:name => name, :message => message, :stacktrace => trace || caller}
    end
    
  end
end