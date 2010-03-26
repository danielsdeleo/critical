module Critical
  module MonkeyPatch
    module Array

      def field(n)
        self[n].criticalize(critical_error_report)
      end

    end
  end
end

class Array
  include Critical::MonkeyPatch::Array
end