module Critical
  module Expectations
    
    module Expectable
      def report
        raise NotImplementedError, "The #report method should be implemented by the including class #{self.class.name}"
      end
    
      def is(matcher)
        if matcher[:block].call(target) == true
          true
        else
          explanation = "expected #{value_name} to be #{matcher[:name]} #{matcher[:arg]}, but it was #{target}"
          report.expectation_failed("ExpectationFailed", explanation, caller)
          false
        end
      end
      alias :should_be :is
      
      def target
        self
      end
      
      def value_name
        if (respond_to?(:reported_value_name) && respond_to?(:owner) && reported_value_name)
          owner.to_s + "[#{reported_value_name.inspect}]"
        else
          "value"
        end
      end
    end
    
    module Matchers
      def exactly(arg)
        {:name => 'exactly', :arg => arg, :block => lambda {|other| other == arg}}
      end
    
      def lte(arg)
        {:name => 'less than or equal to', :arg => arg, :block => lambda { |other| other <= arg }}
      end
      alias :less_than_or_equal_to :lte
      
      def less_than(arg)
        {:name => 'less than', :arg => arg, :block => lambda { |other| other < arg }}
      end
      alias :lt :less_than
    
      def gte(arg)
        {:name => 'greater than or equal to', :arg => arg, :block => lambda { |other| other >= arg }}
      end
      alias :greater_than_or_equal_to :gte
      
      def greater_than(arg)
        {:name => 'greater than', :arg => arg, :block => lambda { |other| other > arg }}
      end
      alias :gt :greater_than
    
    end
    
  end
end