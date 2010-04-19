module Critical
  module MonkeyPatch
    module String
  
      def last_line
        split("\n").last
      end
  
      def line(line_number)
        split("\n")[line_number]
      end
  
      def fields(regexp)
        unless regexp.kind_of?(Regexp)
          raise ArgumentError, "You must give a Regular Expression to parse fields (you gave `#{regexp}')"
        end
        
        if match_data = regexp.match(self)
          match_data.captures
        else
          nil
        end
      end

    end
  end
end

class String
  include Critical::MonkeyPatch::String
end