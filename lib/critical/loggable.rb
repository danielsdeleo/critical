require 'pp'
require 'stringio'
require 'logger'
require 'singleton'
require 'time'

module Critical

  class InvalidLoggerField < ArgumentError
  end
  
  class InvalidLogLevel < ArgumentError
  end
  
  class PrettyPrintStringIO < StringIO
    include PP::PPMethods
    
    def singleline_pp(obj)
      ::PP.singleline_pp(obj, self)
    end
  end

  module Loggable
    module Formatters
      
      class Ruby < ::Logger::Formatter
        VALID_FIELDS = [:time, :severity, :sender, :message]
        
        def self.include_fields(*fields)
          fields = fields.flatten.map do |field|
            field = field.to_sym
            assert_valid_field_name!(field)
            field
          end
          
          @active_fields = fields
        end
        
        def self.assert_valid_field_name!(field)
          unless VALID_FIELDS.include?(field)
            raise InvalidLoggerField, "'#{field}' is not a valid logger field. Valid field names are #{VALID_FIELDS.join(", ")}"
          end
        end
        
        def self.active_fields
          @active_fields || VALID_FIELDS
        end
        
        def call(severity, time, progname, msg)
          io = PrettyPrintStringIO.new
          io.singleline_pp(hashify(severity, time, progname, msg))
          io.string + "\n"
        end
        
        private
        
        def active_fields
          self.class.active_fields
        end
        
        def hashify(severity, time, progname, msg)
          hashified_msg = {}
          hashified_msg[:time]      = time.rfc2822      if active_fields.include?(:time)
          hashified_msg[:severity]  = severity          if active_fields.include?(:severity)
          hashified_msg[:sender]    = progname          if active_fields.include?(:sender)
          hashified_msg[:message]   = msg               if active_fields.include?(:message)
          hashified_msg
        end
      end
      
    end
    
    class Logger
      include Singleton
      LEVELS = { :debug=>::Logger::DEBUG, :info=>::Logger::INFO, :warn=>::Logger::WARN, :error=>::Logger::ERROR, :fatal=>::Logger::FATAL}
      
      def initialize
        reset!
      end
      
      def reset!
        @logger = ::Logger.new(io_out)
        @logger.formatter = Formatters::Ruby.new
        @logger.level = level_to_const(:debug)
      end
      
      def io_out
        STDOUT
      end
      
      def level_to_const(level)
        unless level = LEVELS[level.to_sym]
          raise InvalidLogLevel, "'#{level}' is not a valid log level. Valid levels are #{LEVELS.join(", ")}"
        end
        level
      end
      
      def level=(new_level)
        @logger.level = level_to_const(new_level)
      end
      
      def level
        @logger.level
      end
      
      def fatal(msg=nil, &block)
        @logger.add(::Logger::FATAL, msg, progname, &block)
      end
      
      def error(msg=nil, &block)
        @logger.add(::Logger::ERROR, msg, progname, &block)
      end
      
      def warn(msg=nil, &block)
        @logger.add(::Logger::WARN, msg, progname, &block)
      end
      
      alias :warning :warn
      
      def info(msg=nil, &block)
        @logger.add(::Logger::INFO, msg, progname, &block)
      end
      
      def debug(msg=nil, &block)
        @logger.add(::Logger::DEBUG, msg, progname, &block)
      end
      
      private
      
      def progname
        "Critical[#{Process.pid}]"
      end

    end
    
    # Returns the Logger instance.
    def log
      Logger.instance
    end
    
  end
end
