require 'rubygems'
require "restclient"

Metric(:http_get) do
  monitors :url
  collects { RestClient.get(url) }
  reports(:status => :integer) {result.code}
  reports(:content) { result.body }
end

Monitor(:web) do
  http_get("http://opscode.com/") do |request|
    request.status.is equal_to 200
    # Hrm, maybe I need to give in and use #should...
    # request.content.at_selector('css-selector').matches "something"
  end
end