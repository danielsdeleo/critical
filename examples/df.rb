# df.rb: An example using critical to process information from df(1)
# and make assertions about it.

Critical::OutputHandler::GroupDispatcher.configure do |dispatcher|
  dispatcher.handler :text
end

# Metrics are functions (methods, really) that gather data and present it in
# usable form. 
Metric(:df) do |df|
	# Parameters that are passed to the collection command
  # You can have several of these; the *first* one declared will
  # be the +default_attribute+ which can be set by passing an argument
  # to initialize
  # Implemented: monitors(:a_variable)
  # Not Implemented: validation, required
  df.monitors(:filesystem, :validate => /\/.*/, :required => true)
	
	# Uses Chef's convention of String=>shell command, Block=>ruby code
	# Uses Rails' convention that :something is a variable in a string
	df.collects "df -k :filesystem"
	
	# Regexp to parse df -k output, used below
	# Can this be made less fugly in a general way?
  df_k_format = /^([\S]+)[\s]+([\d]+)[\s]+([\d]+)[\s]+([\d]+)[\s]+([\d]+)%[\s]+([\S]+)$/

	# multiple reporting options (methods) are allowed. The output can be coerced
	# to a desired type by specifying the report name as a hash of the form
	# :name => :desired_output_type
	df.reports(:percentage => :integer) do
	  # command results should be stored as a subclass of string with extra sugar on top
	  # if collect is given a block, the result should be checked for Stringness and converted
	  # when appropriate
		result.last_line.fields(df_k_format).field(4)
	end
	
	df.reports(:blocks_used) do
	  result.last_line.fields(df_k_format).field(3)
	end
end

# Monitors use metrics to gather data. They can make judgements about that data
# i.e., the root partition should be less than 90% full, or forward the data to
# external aggregators (not yet implememnted.)
#
# Monitors are also where you define your scheduling.
Monitor(:unix_box) do
  
  # Specify collection intervals with +every+ or +collect_every+
  # The +every+ form takes a block, each monitor you define inside the block
  # will be scheduled to run at that interval.
  every(5=>:minutes) do
    
    # Monitor statements can be nested, this nesting will be included in the
    # collected data for tracking/tagging purposes.
    # You can also use a block variable with Monitor if you prefer that style:
    Monitor(:disks) do |disks|
      
      # Monitors are defined in terms of the metrics they use. In this case,
      # we use the df() metric defined above. This metric is 
      # /unix_box/disks/df["/"] in the namespace.
      #
      # If you hadn't passed a block variable to +Monitor+ above, you could
      # just write <tt>df("/")</tt> instead of <tt>disks.df("/")</tt>
      disks.df("/") do |root_partition|
        # implemented:
        root_partition.percentage.is      less_than(85)
        # not implemented:
        ###root_partition.percentage.trend("root partition", opts={})
      end
    end
  end
end
