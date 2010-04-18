module Critical
  module MonkeyPatch
    module Array

      def field(n)
        self[n]
      end

    end
  end
end

class Array
  include Critical::MonkeyPatch::Array
end