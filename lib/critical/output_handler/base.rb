module Critical
  module OutputHandler
    class Base
      
      def self.symbol_to_handler
        @@symbol_to_handler ||= {}
      end
      
      private
      
      def self.inherited(subclass)
        symbol_to_handler[class_name_to_snake_symbol(subclass)] = subclass unless subclass.name.to_s.empty?
      end
      
      def self.class_name_to_snake_symbol(subclass)
        basename = subclass.name.split("::").last
        basename.gsub(/\B[A-Z]/, '_\&').downcase.sub(/(_handler)$/, '').to_sym
      end
      
      public
      
      
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
    
  end
end