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

  module LibraryMetricLoader
    extend self
    extend Loggable

    METRIC_PATH_SPEC = /(#{Regexp.escape 'critical/metrics/'}(.+))\.rb/
    #' fix syntax highlighting in vim :(
    METRIC_REQUIRE_PATHS = {}

    def add_library_metric(path)
      match = METRIC_PATH_SPEC.match(path)
      METRIC_REQUIRE_PATHS[match[2]] = path
    end

    begin
      require 'rubygems'
      Gem.find_files('critical/metrics/*.rb').each do |file|
        add_library_metric(file)
      end
    rescue LoadError
    end

    Dir[File.expand_path('../metrics/*.rb', __FILE__)].each do |file|
      add_library_metric(file)
    end

    def require_metric(name)
      if path = METRIC_REQUIRE_PATHS[name]
        FileLoader.load_metrics_and_monitors_in(path)
      else
        log.debug { "Metric #{name} not found" }
        msg = "The metric #{name} was not found in the stdlib or any installed gems\n"
        msg << "Available metrics are: #{METRIC_REQUIRE_PATHS.keys.join(',')}"
        raise LoadError, msg
      end
    end

    def reset_metric_load_paths!(*paths)
      METRIC_REQUIRE_PATHS.clear
      paths.each do |path|
        Dir[File.join(path, '*.rb')].each do |file|
          add_library_metric(file)
        end
      end
    end

  end

end
