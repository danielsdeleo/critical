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

FIXTURES_DIR = File.expand_path("../fixtures", __FILE__)

Critical.config.log_level = :fatal
