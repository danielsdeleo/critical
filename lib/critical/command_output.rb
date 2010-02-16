module Critical
  class CommandOutput < String
    
    def last_line
      preserve_class {split("\n").last}
    end
    
    def fields(regexp)
      OutputFields.new(regexp.match(self).captures.map { |match| co(match) })
    end
    
    private
    
    def co(string)
      self.class.new(string)
    end
    
    def preserve_class(&block)
      self.class.new(instance_eval(&block))
    end
    
  end
end
