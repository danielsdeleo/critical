module Critical
  module CoreExt
    module Base
      attr_accessor :critical_error_report
      
      def criticalize(report)
        self.critical_error_report = report
        self
      end
    end
  end
end

class Object
  include Critical::CoreExt::Base
end
