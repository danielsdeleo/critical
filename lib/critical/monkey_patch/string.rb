module Critical
  module MonkeyPatch
    module String
  
      def last_line
        split("\n").last.criticalize(critical_error_report)
      end
  
      def line(line_number)
        split("\n")[line_number].criticalize(critical_error_report)
      end
  
      def fields(regexp)
        unless regexp.kind_of?(Regexp)
          raise ArgumentError, "You must give a Regular Expression to parse fields (you gave `#{regexp}')"
        end
    
        match_data = regexp.match(self)
        if match_data.nil?
          critical_error_report.annotate("Regexp Match Failure", "Could not parse fields from #{self.inspect} with regexp #{regexp.inspect}")
          nil
        else
          match_data.captures.map { |match| match.criticalize(critical_error_report) }.criticalize(critical_error_report)
        end
      end

    end
  end
end

class String
  include Critical::MonkeyPatch::String
end