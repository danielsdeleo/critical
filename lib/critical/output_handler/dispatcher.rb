module Critical
  module OutputHandler
    # A proxy for multiple output handlers so that you can output to, say, 
    # STDOUT, a log file, and email at the same time
    class Dispatcher < Base
      
      def self.configure
        yield self
      end
      
      def self.handler(type, opts={})
        handlers[fetch_handler_class(type)] = opts
        yield opts if block_given?
      end
      
      def self.handlers
        @handlers ||= {}
      end
      
      private
      
      def self.fetch_handler_class(klass_or_symbol)
        return klass_or_symbol if klass_or_symbol.kind_of?(Class)
        
        unless klass = symbol_to_handler[klass_or_symbol]
          valid_handler_symbols = symbol_to_handler.keys.map {|k|k.inspect }.join(", ")
          explanation = "No handler with the key `#{klass_or_symbol.inspect}' exists, "
          explanation << "valid handlers are (#{valid_handler_symbols}) or (#{symbol_to_handler.values.join(", ")})"
          raise ArgumentError, explanation
        end
        klass
      end
      
      public
      
      def initialize
        self.class.handlers.each do |handler_klass, handler_opts|
          proxied_handlers << handler_klass.new(handler_opts)
        end
      end
      
      def proxied_handlers
        @proxied_handlers ||= []
      end
      
      def metric=(metric_collector)
        super
        @proxied_handlers.each { |h| h.metric = metric_collector }
      end
      
      def collection_started(*args)
        dispatch :collection_started, *args
      end
    
      def collection_succeeded(*args)
        dispatch :collection_succeeded, *args
      end
      
      def annotate(error, message=nil, trace=nil)
        dispatch :annotate, error, message, trace
      end
      
      def collection_failed(error, message=nil, trace=nil)
        dispatch :collection_failed, error, message, trace
      end
      
      def processing_failed(error, message=nil, trace=nil)
        dispatch :processing_failed, error, message, trace
      end
      
      def expectation_failed(error, message=nil, trace=nil)
        dispatch :expectation_failed, error, message, trace
      end
      
      def expectation_succeeded(error, message=nil, trace=nil)
        dispatch :expectation_succeeded, error, message, trace
      end
      
      def collection_completed(*args)
        dispatch :collection_completed, *args
      end
      
      private
      
      def dispatch(method, *args)
        @proxied_handlers.each { |handler| handler.send(method, *args) }
      end
      
    end
    
  end
end