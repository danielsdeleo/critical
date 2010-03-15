module Critical
  module FileLoader
    class FileLoaderError < StandardError
    end
    
    extend self
    
    def load_in_context(context_obj, file)
      filename = file if File.file?(file)
      filename = file + ".rb" if File.file?(file + ".rb")
      no_such_file!(file) unless filename
      context_obj.instance_eval(IO.read(filename), filename, 1)
    end
    
    def no_such_file!(file)
      raise FileLoaderError, "Could not load the file at #{file}"
    end
  end
end