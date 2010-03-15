module Critical
  
  # Instead of rails-style monkey-patching everything, the CoreExt here are
  # primarily based on subclassing. Only a #criticalize method is added to
  # Object; this method attempts to convert an object to the customized
  # subclass. This is less convenient, but Critical isn't using many core
  # extensions, and they're only used in a few places in the DSL.
  module CoreExt
    module Object
      # Try to convert the object to a custom subclass,
      # for example convert a String into a CriticalString
      # If there is no custom subclass, return self.
      def criticalize
        self
      end
    end
    
    module Base
      module ClassMethods
        def extends_class(klass)
          criticalize_method=<<-CRITICALIZE
            def criticalize(report=nil)
              o = #{self.name}.new(self)
              o.report = report if report
              o
            end
          CRITICALIZE
          klass.class_eval(criticalize_method)
        end
      end
      
      attr_accessor :report

      def initialize(superclass_obj, report=nil)
        @report = report
        super(superclass_obj)
      end

      def preserve_class(&block)
        return_val = self.class.new(instance_eval(&block))
        return_val.report = report
        return_val
      end
    end
  end
  
  class CriticalArray < Array
    extend CoreExt::Base::ClassMethods
    include CoreExt::Base
    
    extends_class ::Array
    
    def field(n)
      self[n]
    end
    
  end

  class CriticalString < String
    extend CoreExt::Base::ClassMethods
    include CoreExt::Base
    
    extends_class ::String
    
    def last_line
      preserve_class {split("\n").last}
    end
    
    def line(line_number)
      preserve_class { split("\n")[line_number] }
    end
    
    def fields(regexp)
      unless regexp.kind_of?(Regexp)
        raise ArgumentError, "You must give a Regular Expression to parse fields (you gave `#{regexp}')"
      end
      
      match_data = regexp.match(self)
      if match_data.nil?
        report.annotate("Regexp Match Failure", "Could not parse fields from #{self.inspect} with regexp #{regexp.inspect}")
        nil
      else
        match_data.captures.map { |match| match.criticalize(report) }.criticalize(report)
      end
    end
    
  end
end

class Object
  include Critical::CoreExt::Object
end
