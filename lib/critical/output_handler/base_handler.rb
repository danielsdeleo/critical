module Critical
  module OutputHandler
    class MetricBaseHandler
      attr_accessor :metric, :collected_at
      
      def initialize(*args)
      end
        
      def collection_started(*args)
      end
    
      def collection_succeeded(*args)
      end
      
      def annotate(error, message=nil, trace=nil)
      end
      
      def collection_failed(error, message=nil, trace=nil)
      end
      
      def processing_failed(error, message=nil, trace=nil)
      end
      
      def expectation_failed(error, message=nil, trace=nil)
      end
      
      def expectation_succeeded(error, message=nil, trace=nil)
      end
      
      def collection_completed(*args)
      end
      
      private
      
      def normalize_exception(error, message=nil, trace=nil)
        if error.kind_of?(Exception)
          name, message, trace = error.class.name, error.message, error.backtrace
        end
        name ||= error
        {:name => name, :message => message, :stacktrace => trace || caller}
      end
    end
    
    class GroupBaseHandler
      
      def self.symbol_to_handler
        @@symbol_to_handler ||= {}
      end
      
      private
      
      def self.inherited(subclass)
        symbol_to_handler[class_name_to_snake_symbol(subclass)] = subclass unless subclass.name.empty?
      end
      
      def self.class_name_to_snake_symbol(subclass)
        basename = subclass.name.split("::").last
        basename.gsub(/\B[A-Z]/, '_\&').downcase.sub(/(_handler|_handler_group|_group_handler)$/, '').to_sym
      end
      
      public
      
      attr_reader :metric_group
      
      def initialize(metric_group, opts={}, &block)
        @metric_group = metric_group
        setup(opts)
        
        run_with_block(&block) if block_given?
      end
      
      # A callback on initialize so you don't have to deal with calling super
      # silliness in subclasses. Just put any option processing you need in 
      # a +setup+ method and bam! done.
      def setup(opts={})
      end
    
      def start(*args)
      end
      
      def metric_report
        raise NotImplementedError, "The #{self.class.name} class must define it's own metric handler generator"
      end
    
      def stop(*args)
      end
      
      private
      
      def run_with_block
        begin
          start
          yield self
        ensure
          stop
        end
      end
      
    end
  end
end