module Critical

  class LoadError < ::LoadError
  end

  module FileLoader
    extend self
    extend Loggable
    
    def load_metrics_and_monitors_in(file_or_dir)
      log.debug { "Loading source file #{file_or_dir}" }
      load_in_context(Critical::DSL::TopLevel, file_or_dir)
    end
    
    def load_in_context(context_obj, file)
      assert_file_exists!(file)
      
      if filename = file_full_name(file)
        load_file_in_context(context_obj, filename)
      elsif filenames = files_in_dir(file)
        filenames.each { |f| load_in_context(context_obj, f) }
      else
        raise LoadError, "Could not load file/directory #{file}. Is it a pipe/device/alien?"
      end
    end
    
    private
    
    def file_full_name(file)
      filename = nil
      filename = file if File.file?(file)
      filename = file + ".rb" if File.file?(file + ".rb")
      File.expand_path(filename) if filename
    end
    
    def files_in_dir(dir)
      if File.directory?(dir)
        log.debug { "Searching directory #{dir} for source files" }
        filenames = Dir["#{dir}/**/*.rb"]
        filenames.map! { |f| File.expand_path(f) }
        filenames
      end
    end
    
    def load_file_in_context(context_obj, filename)
      begin
        context_obj.instance_eval(IO.read(filename), filename, 1)
      rescue Errno::EACCES => e
        raise Critical::LoadError, "permission denied trying to access file #{file}\n Original error: #{e.message}"
      end
    end
    
    def assert_file_exists!(file)
      no_such_file!(file) unless File.exist?(file) || File.exist?(file + ".rb")
    end
    
    def no_such_file!(file)
      raise Critical::LoadError, "Could not load the file #{file} -- The OS says it doesn't exist"
    end
  end
end