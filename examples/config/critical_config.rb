require 'rubygems'

Critical.configure do |critical|
  root = File.dirname(__FILE__) + '/../'
  critical.require root + "metrics/"
  critical.require root + "monitors/"
  
  critical.reporting do |reports|
    reports.as  :text, :output => STDOUT
    #reports.via :http, :url => "http://critical.example.com/" # No Implementation Yet
  end
  
  critical.log_format.include_fields :time, :severity, :sender, :message
end