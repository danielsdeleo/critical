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
          explanation = "expected value to be #{matcher[:name]} #{matcher[:arg]}, but it was #{self}"
          report.expectation_failed!("ExpectationFailed", explanation, caller)
          false
        end
      end
      alias :should_be :is
      
      def target
        self
      end
    end
    
    module Matchers
      def exactly(arg)
        {:name => 'exactly', :arg => arg, :block => lambda {|other| other == arg}}
      end
    
      def lte(arg)
        {:name => 'less than or equal to', :arg => arg, :block => lambda { |other| other <= arg }}
      end
    
      def gte(arg)
        {:name => 'greater than or equal to', :arg => arg, :block => lambda { |other| other >= arg }}
      end
    end
    
  end
end