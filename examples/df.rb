$: << File.dirname(__FILE__) + "/../lib/"
require "critical"

# Eventually use a chef-like from_file() method to negate the need for this
# boilerplate
include Critical::DSL

df_metric = Metric(:df) do |df|
	# Parameters that are passed to the collection command
  # You can have several of these; the *first* one declared will
  # be the +default_attribute+ which can be set by passing an argument
  # to initialize
  df.monitors(:filesystem, :validate => /\/.*/, :required => true)
	
	# Use Chef's convention of String=>shell command, Block=>ruby code
	# use Rails' convention that :something is a variable
	df.collects "df -k :filesystem"
	
	# Regexp to parse df -k output, used below
  parse = /^([\S]+)[\s]+([\d]+)[\s]+([\d]+)[\s]+([\d]+)[\s]+([\d]+)%[\s]+([\S]+)$/

	# multiple reporting options (methods) are allowed
	df.reports(:percentage) do
	  # command results should be stored as a subclass of string with extra sugar on top
	  # if collect is given a block, the result should be checked for Stringness and converted
	  # when appropriate
	  puts "reporting percentage..."
	  puts "result: #{result}"
	  puts "result-last_line: #{result.last_line}"
	  puts "..."
    puts "result fields: #{result.last_line.fields(parse)}"
    puts "result field 4: #{result.last_line.fields(parse).field(4)}"
		result.last_line.fields(parse).field(4)
	end
	
	df.reports(:blocks_used) do
	  result.last_line.fields(parse).field(3)
	end
end

require 'pp'
puts "df instance methods"
pp df_metric.instance_methods.sort
##### so far, we have:

unix_host_checks = Monitor(:unix_host) do
  ## planned featurez ##
  #
  # block form scheduling?
  #every(30 => :minutes) do; end
  #
  # non block declaration form scheduling? 
  #check_every(30 => :minutes)
  
  ## implemented featurez ##
  
  df("/") do |root_partition|
    root_partition.percentage.is      less_than(91)
    root_partition.percentage.trend("root partition", opts={})
  end
end

unix_host_checks.collect_all