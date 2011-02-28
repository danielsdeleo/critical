# Metrics are functions (methods, really) that gather data and present it in
# usable form. 
Metric(:disk_utilization) do
  # Parameters that are passed to the collection command
  # You can have several of these; the *first* one declared will
  # be the +default_attribute+ which can be set by passing an argument
  # to initialize
  # Implemented: monitors(:a_variable)
  # Not Implemented: validation, required
  monitors(:filesystem, :validate => /\/.*/, :required => true)
  
  # Uses Chef's convention of String=>shell command, Block=>ruby code
  # Uses Rails' convention that :something is a variable in a string
  collects "df -k :filesystem"
  
  # Regexp to parse df -k output, used below
  # Can this be made less fugly in a general way?
  df_k_format = /^([\S]+)[\s]+([\d]+)[\s]+([\d]+)[\s]+([\d]+)[\s]+([\d]+)%[\s]+([\S]+)$/

  # multiple reporting options (methods) are allowed. The output can be coerced
  # to a desired type by specifying the report name as a hash of the form
  # :name => :desired_output_type
  reports(:percentage => :integer) do
    # command results should be stored as a subclass of string with extra sugar on top
    # if collect is given a block, the result should be checked for Stringness and converted
    # when appropriate
    result.last_line.fields(df_k_format).field(4)
  end
  
  reports(:blocks_used) do
    result.last_line.fields(df_k_format).field(3)
  end
end
