require 'pp'
require File.dirname(__FILE__) + '/../lib/critical'

Dir[File.dirname(__FILE__) + '/behaviors/*.rb'].each do |shared|
  require shared
end

module Critical
  module TestHarness
  end
end

include Critical

Critical.config.log_level = :fatal